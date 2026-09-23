import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:sms_app/data/services/storage_service.dart';
import 'package:sms_app/core/constants/api_constants.dart';
import 'package:sms_app/core/utils/logger.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? socket;
  final _statsUpdateController = StreamController<void>.broadcast();
  
  Stream<void> get statsUpdateStream => _statsUpdateController.stream;

  void initSocket() {
    try {
      final user = StorageService.getUser();
      if (user == null) return;

      if (socket != null && socket!.connected) {
        return;
      }

      disconnect();

      final String baseUrl = ApiConstants.baseUrl.replaceAll('/smsmitra/v1', '');
      
      socket = io.io(baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 3000,
      });

      socket!.onConnect((_) {
        logger.i('Socket Connected');
        socket?.emit('join', user.id);
      });

      socket!.on('stats_update', (data) {
        logger.d('Socket: Stats Update Received');
        if (!_statsUpdateController.isClosed) {
          _statsUpdateController.add(null);
        }
      });

      socket!.onConnectError((err) => logger.w('Socket Connect Error: $err'));
      socket!.onError((err) => logger.w('Socket Error: $err'));
      socket!.onDisconnect((_) => logger.i('Socket Disconnected'));

      socket!.connect();
    } catch (e) {
      logger.e('SocketService init error: $e');
    }
  }

  void disconnect() {
    try {
      if (socket != null) {
        socket!.dispose();
        socket = null;
      }
    } catch (e) {
      logger.e('SocketService disconnect error: $e');
    }
  }
}
