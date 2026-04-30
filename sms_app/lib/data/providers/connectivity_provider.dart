import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline }

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  ConnectivityNotifier() : super(ConnectivityStatus.online) {
    _checkConnectivity();
    // In a real app, we would use connectivity_plus package here.
    // For now, we'll heartbeat a small request or just assume online until a request fails.
  }

  void setOffline() => state = ConnectivityStatus.offline;
  void setOnline() => state = ConnectivityStatus.online;

  Future<void> _checkConnectivity() async {
    try {
      final dio = Dio();
      await dio.get(
        'https://google.com',
        options: Options(receiveTimeout: const Duration(seconds: 3)),
      );
      setOnline();
    } catch (_) {
      setOffline();
    }
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
      return ConnectivityNotifier();
    });
