import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/sim_service.dart';
import '../services/sms_api_service.dart';
import '../services/sms_service.dart';
import '../services/socket_service.dart';
import '../cache/cache_service.dart';

/// Provider for the central Dio-based API client.
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Provider for SIM hardware queries and telephony services.
final simServiceProvider = Provider<SimService>((ref) {
  return SimService();
});

/// Provider for SMS cloud API interactions.
final smsApiServiceProvider = Provider<SmsApiService>((ref) {
  return SmsApiService();
});

/// Provider for low-level SMS hardware dispatch.
final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService();
});

/// Provider for authentication network service.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for caching operations.
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

/// Provider for WebSocket live updates.
final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});
