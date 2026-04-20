import 'package:hive/hive.dart';

part 'sms_log_model.g.dart';

@HiveType(typeId: 2)
class SmsLogModel extends HiveObject {
  @HiveField(0)
  final String? id;
  
  @HiveField(1)
  final String receiverNumber;
  
  @HiveField(2)
  final String message;
  
  @HiveField(3)
  final String status;
  
  @HiveField(4)
  final String? simId;
  
  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String? errorMessage;

  SmsLogModel({
    this.id,
    required this.receiverNumber,
    required this.message,
    required this.status,
    this.simId,
    required this.createdAt,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'receiverNumber': receiverNumber,
    'message': message,
    'status': status,
    'simId': simId,
    'createdAt': createdAt.toIso8601String(),
    'errorMessage': errorMessage,
  };

  factory SmsLogModel.fromJson(Map<String, dynamic> json) => SmsLogModel(
    id: json['id']?.toString(),
    receiverNumber: json['receiverNumber'] ?? '',
    message: json['message'] ?? '',
    status: json['status'] ?? 'pending',
    simId: json['simId']?.toString(),
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    errorMessage: json['errorMessage'],
  );
}
