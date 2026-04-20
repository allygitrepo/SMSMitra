import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<void> generateSmsReport({
    required List<dynamic> logs,
    required Map<String, int> stats,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final doc = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final filterFormat = DateFormat('dd MMM yyyy');

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SMS Mitra Report',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Filters info
            if (startDate != null || endDate != null)
              pw.Text(
                'Period: ${startDate != null ? filterFormat.format(startDate) : "Start"} to ${endDate != null ? filterFormat.format(endDate) : "End"}',
                style: pw.TextStyle(
                    fontSize: 12, color: pdf.PdfColors.grey700),
              ),
            pw.SizedBox(height: 20),

            // Summary Stats
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Sent', stats['sent'] ?? 0, pdf.PdfColors.green),
                _buildStatItem(
                    'Failed', stats['failed'] ?? 0, pdf.PdfColors.red),
                _buildStatItem(
                    'Pending', stats['pending'] ?? 0, pdf.PdfColors.orange),
              ],
            ),
            pw.SizedBox(height: 30),

            // Table
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Receiver', 'Message', 'SIM', 'Status'],
              data: logs.map((log) {
                return [
                  dateFormat.format(DateTime.parse(log['createdAt'])),
                  log['receiverNumber'] ?? '',
                  log['message'] ?? '',
                  log['simId'] ?? '-',
                  log['status'].toString().toUpperCase(),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: pdf.PdfColors.white),
              headerDecoration:
                  const pw.BoxDecoration(color: pdf.PdfColors.blueGrey800),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (pdf.PdfPageFormat format) async => doc.save());
  }

  static pw.Widget _buildStatItem(String label, int value, pdf.PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(value.toString(),
            style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: color)),
      ],
    );
  }
}
