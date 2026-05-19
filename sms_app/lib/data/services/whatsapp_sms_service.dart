import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/utils/logger.dart';

class WhatsAppSmsService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.6:3000'));

  static const String _boxName = 'whatsapp_prefs';
  static const String _linkedKey = 'is_linked';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  bool isLinked() {
    if (!Hive.isBoxOpen(_boxName)) return false;
    final box = Hive.box(_boxName);
    return box.get(_linkedKey, defaultValue: false);
  }

  Future<void> setLinked(bool value) async {
    if (!Hive.isBoxOpen(_boxName)) await init();
    final box = Hive.box(_boxName);
    await box.put(_linkedKey, value);
  }

  Future<Map<String, dynamic>> startSession(String sessionId) async {
    try {
      final response = await _dio
          .post('/api/auth/start-session', data: {'sessionId': sessionId});
      return response.data;
    } catch (e) {
      logger.e('Failed to start WhatsApp session: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStatus(String sessionId) async {
    try {
      final response = await _dio
          .get('/api/auth/status', queryParameters: {'sessionId': sessionId});
      return response.data;
    } catch (e) {
      logger.e('Failed to get WhatsApp status: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> disconnect(String sessionId) async {
    try {
      final response =
          await _dio.post('/api/auth/disconnect', data: {'sessionId': sessionId});
      await setLinked(false);
      return response.data;
    } catch (e) {
      logger.e('Failed to disconnect WhatsApp: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendBulkMessages({
    required List<Map<String, String>> messages,
    required String sessionId,
    String? userId,
    String? orgCode,
  }) async {
    try {
      final response = await _dio.post('/api/messages/bulk', data: {
        'messages': messages,
        'sessionId': sessionId,
        'userId': userId,
        'orgCode': orgCode,
        'simId': 'whatsapp',
      });
      return response.data;
    } catch (e) {
      logger.e('Failed to send bulk WhatsApp messages: $e');
      rethrow;
    }
  }
}
