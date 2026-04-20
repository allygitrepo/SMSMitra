import 'package:hive/hive.dart';

part 'cached_data_model.g.dart';

@HiveType(typeId: 4)
class CachedDataModel extends HiveObject {
  @HiveField(0)
  final dynamic data;
  
  @HiveField(1)
  final DateTime timestamp;

  CachedDataModel({
    required this.data,
    required this.timestamp,
  });

  bool isExpired(Duration duration) {
    return DateTime.now().difference(timestamp) > duration;
  }
}
