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
    final user = StorageService.getUser();
    if (user == null) return;

    String baseUrl = ApiConstants.baseUrl.replaceAll('/smsmitra/v1', '');
    
    socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.connect();

    socket!.onConnect((_) {
      logger.i('Socket Connected');
      socket!.emit('join', user.id);
    });

    socket!.on('stats_update', (data) {
      logger.d('Socket: Stats Update Received');
      _statsUpdateController.add(null);
    });

    socket!.onDisconnect((_) => logger.i('Socket Disconnected'));
  }

  void disconnect() {
    if (socket != null) {
      socket!.disconnect();
    }
  }
}
