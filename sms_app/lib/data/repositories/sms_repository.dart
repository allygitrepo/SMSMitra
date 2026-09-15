import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exceptions.dart';
import '../services/sms_service.dart';
import '../services/sms_api_service.dart';
import '../services/storage_service.dart';
import '../../features/settings/settings_provider.dart';
import '../../features/home/stats_provider.dart';

import '../services/sim_service.dart';

final smsRepositoryProvider = Provider<SmsRepository>((ref) {
  return SmsRepository(ref);
});

/// Central Repository orchestrating permissions, quota verification,
/// native SMS dispatching, and remote backend logging.
class SmsRepository {
  final Ref _ref;
  final SmsService _smsService = SmsService();
  final SimService _simService = SimService();
  final SmsApiService _smsApiService = SmsApiService();

  SmsRepository(this._ref);

  /// Executes full SMS dispatch flow with quota validation and delivery tracking.
  Future<void> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    // 1. Permission Check
    final hasPermission = await _smsService.requestPermissions();
    if (!hasPermission) {
      throw const TelephonyException('SMS permission denied. Please enable SMS permissions in device settings.');
    }

    // 2. Quota Check
    final settings = _ref.read(settingsProvider);
    final stats = _ref.read(smsStatsProvider);
    final sentToday = stats['sentToday'] ?? 0;
    final dailyLimit = settings.dailySmsLimit;

    if (dailyLimit != -1 && sentToday >= dailyLimit) {
      throw QuotaException(
        'Daily SMS quota reached ($sentToday/$dailyLimit). Increase limit in SIM settings.',
        limit: dailyLimit,
        sent: sentToday,
      );
    }

    final user = StorageService.getUser();
    final activeSimId = settings.activeSimId;

    try {
      // 3. Native Telephony Dispatch
      await _smsService.sendSms(
        number: phoneNumber,
        message: message,
        simId: activeSimId,
      );

      // 4. Remote Log Sync
      if (user != null) {
        await _smsApiService.createManualLog(
          userId: user.id.toString(),
          phoneNumber: phoneNumber,
          message: message,
          status: 'sent',
          simId: activeSimId,
        );
      }

      // 5. Local State & Cache Update
      _ref.read(smsStatsProvider.notifier).incrementSent();
    } catch (e) {
      // Log failure to backend
      if (user != null) {
        await _smsApiService.createManualLog(
          userId: user.id.toString(),
          phoneNumber: phoneNumber,
          message: message,
          status: 'failed',
          errorMessage: e.toString(),
          simId: activeSimId,
        );
      }

      _ref.read(smsStatsProvider.notifier).incrementFailed();
      if (e is AppException) rethrow;
      throw TelephonyException('Failed to send SMS: ${e.toString()}');
    }
  }

  /// Syncs SIM cards with the backend gateway server.
  Future<bool> syncSimCards() async {
    final user = StorageService.getUser();
    if (user == null) return false;

    final settings = _ref.read(settingsProvider);
    final sims = await _simService.getAvailableSims();
    await _smsApiService.syncSims(
      userId: user.id.toString(),
      sims: sims,
      settings: settings,
    );
    return true;
  }
}
