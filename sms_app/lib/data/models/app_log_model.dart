import 'package:hive/hive.dart';

part 'app_log_model.g.dart';

@HiveType(typeId: 5)
class AppLogModel extends HiveObject {
  @HiveField(0)
  final String message;

  @HiveField(1)
  final String level; // 'info', 'error', 'warning'

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String? details;

  AppLogModel({
    required this.message,
    this.level = 'info',
    required this.timestamp,
    this.details,
  });
}
