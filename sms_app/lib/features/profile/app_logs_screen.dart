import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/services/storage_service.dart';
import '../../data/models/app_log_model.dart';

class AppLogsScreen extends StatefulWidget {
  const AppLogsScreen({super.key});

  @override
  State<AppLogsScreen> createState() => _AppLogsScreenState();
}

class _AppLogsScreenState extends State<AppLogsScreen> {
  List<AppLogModel> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _logs = StorageService.getAppLogs();
    });
  }

  void _clearLogs() async {
    await StorageService.clearAppLogs();
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(child: Text('No system logs found'))
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return ListTile(
                  leading: _getIcon(log.level),
                  title: Text(log.message),
                  subtitle: Text(
                    '${DateFormat('HH:mm:ss.SSS').format(log.timestamp)}${log.details != null ? '\n${log.details}' : ''}',
                  ),
                  isThreeLine: log.details != null,
                );
              },
            ),
    );
  }

  Widget _getIcon(String level) {
    switch (level) {
      case 'error':
        return const Icon(Icons.error, color: Colors.red);
      case 'warning':
        return const Icon(Icons.warning, color: Colors.orange);
      case 'info':
      default:
        return const Icon(Icons.info, color: Colors.blue);
    }
  }
}
