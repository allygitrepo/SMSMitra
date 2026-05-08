import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sms_app/data/services/storage_service.dart';
import 'package:sms_app/core/constants/api_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  final _statsUpdateController = StreamController<void>.broadcast();
  
  Stream<void> get statsUpdateStream => _statsUpdateController.stream;

  void initSocket() {
    final user = StorageService.getUser();
    if (user == null) return;

    String baseUrl = ApiConstants.baseUrl.replaceAll('/smsmitra/v1', '');
    
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      debugPrint('Socket Connected');
      socket!.emit('join', user.id);
    });

    socket!.on('stats_update', (data) {
      debugPrint('Socket: Stats Update Received');
      _statsUpdateController.add(null);
    });

    socket!.onDisconnect((_) => debugPrint('Socket Disconnected'));
  }

  void disconnect() {
    if (socket != null) {
      socket!.disconnect();
    }
  }
}
