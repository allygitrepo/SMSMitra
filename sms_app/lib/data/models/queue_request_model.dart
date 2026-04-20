import 'package:hive/hive.dart';

part 'queue_request_model.g.dart';

@HiveType(typeId: 3)
class QueueRequestModel extends HiveObject {
  @HiveField(0)
  final String path;
  
  @HiveField(1)
  final String method;
  
  @HiveField(2)
  final Map<dynamic, dynamic> data;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  final int retryCount;

  QueueRequestModel({
    required this.path,
    required this.method,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });
}
