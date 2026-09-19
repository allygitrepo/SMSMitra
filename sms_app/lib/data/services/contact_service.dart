import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/contact_model.dart';
import 'bulk_sms_service.dart';

/// Service to request contacts permission and fetch device contacts using native channel.
class ContactService {
  static const MethodChannel _channel = MethodChannel('com.example.sms_app/sim_info');

  List<DeviceContact>? _cachedContacts;

  /// Check if contacts permission is granted
  Future<bool> hasPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  /// Request contacts permission
  Future<bool> requestPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// Fetches all device contacts with valid phone numbers
  Future<List<DeviceContact>> getContacts({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedContacts != null) {
      return _cachedContacts!;
    }

    final hasPerm = await hasPermission();
    if (!hasPerm) {
      final granted = await requestPermission();
      if (!granted) {
        throw Exception('Contacts permission is required to select contacts.');
      }
    }

    try {
      final dynamic rawList = await _channel.invokeMethod<dynamic>('getContacts');

      if (rawList is List) {
        final contacts = <DeviceContact>[];
        for (final item in rawList) {
          if (item is Map) {
            final rawPhone = item['phone']?.toString() ?? '';
            final formatted = BulkSmsService.formatPhoneNumber(rawPhone);
            if (formatted.replaceAll('+', '').length >= 8) {
              contacts.add(DeviceContact(
                id: item['id']?.toString() ?? '',
                name: (item['name']?.toString() ?? '').trim().isNotEmpty
                    ? item['name'].toString().trim()
                    : 'Unknown Name',
                phone: formatted,
              ));
            }
          }
        }
        _cachedContacts = contacts;
        return contacts;
      }
      return [];
    } on PlatformException catch (e) {
      throw Exception('Failed to load contacts: ${e.message}');
    } catch (e) {
      throw Exception('Error loading contacts: $e');
    }
  }

  /// Clears in-memory cache
  void clearCache() {
    _cachedContacts = null;
  }
}
