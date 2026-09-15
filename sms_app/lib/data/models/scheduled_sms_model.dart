import 'package:flutter/foundation.dart';

@immutable
class ScheduledSmsModel {
  final int? id;
  final int userId;
  final String receiverNumber;
  final String message;
  final String? simId;
  final DateTime scheduledAt;
  final String status; // 'scheduled', 'processing', 'completed', 'cancelled', 'failed'
  final DateTime? executedAt;
  final String? errorMessage;
  final int? logId;
  final DateTime createdAt;

  const ScheduledSmsModel({
    this.id,
    required this.userId,
    required this.receiverNumber,
    required this.message,
    this.simId,
    required this.scheduledAt,
    this.status = 'scheduled',
    this.executedAt,
    this.errorMessage,
    this.logId,
    required this.createdAt,
  });

  bool get isPending => status == 'scheduled';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isFailed => status == 'failed';

  ScheduledSmsModel copyWith({
    int? id,
    int? userId,
    String? receiverNumber,
    String? message,
    String? simId,
    DateTime? scheduledAt,
    String? status,
    DateTime? executedAt,
    String? errorMessage,
    int? logId,
    DateTime? createdAt,
  }) {
    return ScheduledSmsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      receiverNumber: receiverNumber ?? this.receiverNumber,
      message: message ?? this.message,
      simId: simId ?? this.simId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      executedAt: executedAt ?? this.executedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      logId: logId ?? this.logId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'userId': userId,
    'receiverNumber': receiverNumber,
    'message': message,
    'simId': simId,
    'scheduledAt': scheduledAt.toIso8601String(),
    'status': status,
    if (executedAt != null) 'executedAt': executedAt!.toIso8601String(),
    if (errorMessage != null) 'errorMessage': errorMessage,
    if (logId != null) 'logId': logId,
    'createdAt': createdAt.toIso8601String(),
  };

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString());
  }

  factory ScheduledSmsModel.fromJson(Map<String, dynamic> json) {
    return ScheduledSmsModel(
      id: _parseInt(json['id']),
      userId: _parseInt(json['userId']) ?? 0,
      receiverNumber: json['receiverNumber']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      simId: json['simId']?.toString(),
      scheduledAt: json['scheduledAt'] != null
          ? (DateTime.tryParse(json['scheduledAt'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      status: json['status']?.toString() ?? 'scheduled',
      executedAt: json['executedAt'] != null
          ? DateTime.tryParse(json['executedAt'].toString())?.toLocal()
          : null,
      errorMessage: json['errorMessage']?.toString(),
      logId: _parseInt(json['logId']),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledSmsModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          receiverNumber == other.receiverNumber &&
          message == other.message &&
          simId == other.simId &&
          scheduledAt == other.scheduledAt &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      receiverNumber.hashCode ^
      message.hashCode ^
      simId.hashCode ^
      scheduledAt.hashCode ^
      status.hashCode;
}
