import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/api_constants.dart';
import '../models/bulk_recipient_model.dart';
import 'api_service.dart';

class BulkParsedResult {
  final List<BulkRecipientModel> recipients;
  final List<String> discoveredColumns;
  final int totalRowsParsed;
  final int duplicatesRemoved;

  const BulkParsedResult({
    required this.recipients,
    required this.discoveredColumns,
    required this.totalRowsParsed,
    required this.duplicatesRemoved,
  });
}

class BulkSmsService {
  final ApiService _apiService;

  static const String sampleCsvTemplate =
      'phone,name,amount,dueDate,invoiceNo\n'
      '+919876543210,Rahul Sharma,1500,25-Oct-2026,INV-1001\n'
      '+919812345678,Priya Patel,2400,28-Oct-2026,INV-1002\n'
      '+919765432109,Amit Verma,350,30-Oct-2026,INV-1003\n';

  BulkSmsService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Saves the sample CSV template to the user's device storage (Downloads / Documents)
  static Future<String> downloadSampleCsvTemplate() async {
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          directory = downloadDir;
        } else {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      directory = await getApplicationDocumentsDirectory();
    }

    directory ??= await getApplicationDocumentsDirectory();

    final filePath = '${directory.path}/smsmitra_sample_template.csv';
    final file = File(filePath);
    await file.writeAsString(sampleCsvTemplate, encoding: utf8);
    return filePath;
  }

  /// Formats phone numbers to standard format (e.g. +919876543210)
  static String formatPhoneNumber(String phone) {
    final String cleaned = phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.length == 10) return '+91$cleaned';
    if (cleaned.length == 12 && cleaned.startsWith('91')) return '+$cleaned';
    return '+$cleaned';
  }

  /// Parses a CSV string or File and extracts all columns dynamically
  static BulkParsedResult parseCsvString(String csvContent) {
    // Strip BOM if present
    String content = csvContent;
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(content);

    if (rows.isEmpty) {
      return const BulkParsedResult(
        recipients: [],
        discoveredColumns: [],
        totalRowsParsed: 0,
        duplicatesRemoved: 0,
      );
    }

    // Header row
    final headerRow = rows.first.map((e) => e.toString().trim()).toList();
    final discoveredColumns = <String>[];
    int phoneColIdx = -1;
    int nameColIdx = -1;

    for (int i = 0; i < headerRow.length; i++) {
      final header = headerRow[i];
      if (header.isEmpty) continue;
      discoveredColumns.add(header);

      final lower = header.toLowerCase();
      if (lower == 'phone' || lower == 'phonenumber' || lower == 'mobile' || lower == 'number' || lower == 'contact') {
        phoneColIdx = i;
      } else if (lower == 'name' || lower == 'fullname' || lower == 'customer' || lower == 'client') {
        nameColIdx = i;
      }
    }

    // Default to first column for phone if not explicitly identified
    if (phoneColIdx == -1 && headerRow.isNotEmpty) {
      phoneColIdx = 0;
    }

    final recipients = <BulkRecipientModel>[];
    final seenPhones = <String>{};
    int duplicatesCount = 0;

    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      if (row.isEmpty || (row.length == 1 && row[0].toString().trim().isEmpty)) {
        continue;
      }

      final rawPhone = phoneColIdx < row.length ? row[phoneColIdx].toString() : '';
      final formattedPhone = formatPhoneNumber(rawPhone);

      // Validate phone length
      if (formattedPhone.replaceAll('+', '').length < 8) {
        continue;
      }

      if (seenPhones.contains(formattedPhone)) {
        duplicatesCount++;
        continue;
      }
      seenPhones.add(formattedPhone);

      final rawName = nameColIdx != -1 && nameColIdx < row.length ? row[nameColIdx].toString().trim() : '';

      // Map ALL custom column values for dynamic placeholder interpolation
      final customData = <String, String>{};
      for (int c = 0; c < headerRow.length && c < row.length; c++) {
        final colName = headerRow[c];
        if (colName.isNotEmpty) {
          customData[colName] = row[c].toString().trim();
        }
      }

      recipients.add(BulkRecipientModel(
        phone: formattedPhone,
        name: rawName,
        customData: customData,
      ));
    }

    return BulkParsedResult(
      recipients: recipients,
      discoveredColumns: discoveredColumns,
      totalRowsParsed: rows.length - 1,
      duplicatesRemoved: duplicatesCount,
    );
  }

  /// Parses a local CSV file path
  static Future<BulkParsedResult> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Selected file does not exist.');
    }

    final content = await file.readAsString(encoding: utf8);
    return parseCsvString(content);
  }

  /// Logs dispatched SMS to backend server
  Future<void> logDispatchedSms({
    required int userId,
    required String phoneNumber,
    required String message,
    String? simId,
    required String status,
    String? errorMessage,
  }) async {
    try {
      await _apiService.client.post<dynamic>(
        ApiConstants.createLog,
        data: {
          'userId': userId,
          'phoneNumber': phoneNumber,
          'message': message,
          'simId': simId,
          'status': status,
          if (errorMessage != null) 'errorMessage': errorMessage,
        },
      );
    } catch (_) {
      // Soft fail logging so campaign continues smoothly
    }
  }
}
