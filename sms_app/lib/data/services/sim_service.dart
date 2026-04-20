import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sim_model.dart';
import 'storage_service.dart';

/// A service to handle SIM card detection and permission checks using mobile_number package.
class SimService {
  /// Requests permission to read phone state and numbers.
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) {
      await StorageService.addAppLog("SIM detection failed: Only Android is supported", level: 'warning');
      debugPrint('SimService: SIM detection is only supported on Android.');
      return false;
    }
    
    debugPrint('SimService: Requesting phone permissions via permission_handler...');
    
    // As per documentation: Use permission_handler for better implementation
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      debugPrint('SimService: Requesting Permission.phone...');
      status = await Permission.phone.request();
    }

    // Also request SMS permission as it's often linked to number retrieval
    var smsStatus = await Permission.sms.status;
    if (!smsStatus.isGranted) {
      debugPrint('SimService: Requesting Permission.sms...');
      await Permission.sms.request();
    }

    debugPrint('SimService: Permission.phone status: $status');
    await StorageService.addAppLog("Phone Permissions checked: ${status.name}");
    
    return status.isGranted;
  }

  /// Fetches the list of available SIM cards on the device.
  Future<List<SimModel>> getAvailableSims() async {
    debugPrint('SimService: Fetching available SIM cards using custom MethodChannel...');
    try {
      const channel = MethodChannel('com.example.sms_app/sim_info');
      final List<dynamic>? result = await channel.invokeMethod('getSimCards');
      
      debugPrint('SimService: Received ${result?.length ?? 0} SIMs from native.');

      if (result == null || result.isEmpty) {
        await StorageService.addAppLog("No SIM cards detected by native channel", level: 'warning');
        debugPrint('SimService: No SIM cards found via native channel.');
        return [];
      }

      final mappedSims = result.map((item) {
        final map = Map<String, dynamic>.from(item);
        debugPrint('SimService: Mapping SIM - Slot: ${map['slotIndex']}, Carrier: ${map['carrierName']}');
        return SimModel(
          id: map['id']?.toString() ?? '0',
          carrierName: map['carrierName']?.toString() ?? 'Unknown Carrier',
          number: map['number']?.toString() ?? 'Unknown Number',
          slotIndex: map['slotIndex'] as int? ?? 0,
        );
      }).toList();
      
      await StorageService.addAppLog("SIMs Detected: ${mappedSims.length}", details: mappedSims.map((s) => s.carrierName).join(', '));
      debugPrint('SimService: Successfully mapped ${mappedSims.length} SIMs.');
      return mappedSims;
    } on PlatformException catch (e) {
      await StorageService.addAppLog("SIM Detection PlatformException: ${e.code}", level: 'error', details: e.message);
      debugPrint('SimService: PlatformException in getAvailableSims: ${e.code} - ${e.message}');
      return [];
    } catch (e) {
      await StorageService.addAppLog("SIM Detection Error", level: 'error', details: e.toString());
      debugPrint('SimService: Error in getAvailableSims: $e');
      return [];
    }
  }

  /// Gets the primary mobile number if available (from native channel).
  Future<String?> getPrimaryNumber() async {
    final sims = await getAvailableSims();
    if (sims.isNotEmpty) {
      final number = sims.first.number;
      return number != 'Unknown Number' ? number : null;
    }
    return null;
  }
}
