import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

@immutable
class FrequentSmsModel {
  final int? id;
  final int userId;
  final String? title;
  final String receiverNumber;
  final String message;
  final String? simId;
  final String frequencyType; // 'daily', 'alternate', 'weekly', 'monthly', 'custom'
  final Map<String, dynamic> frequencyConfig;
  final String dispatchTime; // "HH:mm" (e.g. "09:30")
  final DateTime startDate;
  final DateTime nextRunAt;
  final DateTime? lastRunAt;
  final int totalDispatchedCount;
  final String status; // 'active', 'paused', 'completed', 'cancelled'
  final DateTime createdAt;

  const FrequentSmsModel({
    this.id,
    required this.userId,
    this.title,
    required this.receiverNumber,
    required this.message,
    this.simId,
    this.frequencyType = 'daily',
    this.frequencyConfig = const <String, dynamic>{},
    this.dispatchTime = '09:00',
    required this.startDate,
    required this.nextRunAt,
    this.lastRunAt,
    this.totalDispatchedCount = 0,
    this.status = 'active',
    required this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCancelled => status == 'cancelled';

  String get formattedTime {
    try {
      final parts = dispatchTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      final temp = DateTime(2026, 1, 1, hour, minute);
      return DateFormat('hh:mm a').format(temp);
    } catch (_) {
      return dispatchTime;
    }
  }

  String get formattedFrequency {
    final timeStr = formattedTime;
    switch (frequencyType) {
      case 'daily':
        return 'Daily @ $timeStr';
      case 'alternate':
        final startFrom = frequencyConfig['startFrom'] == 'tomorrow' ? 'Tomorrow' : 'Today';
        return 'Alternate Days (from $startFrom) @ $timeStr';
      case 'weekly':
        final daysOfWeek = (frequencyConfig['daysOfWeek'] as List<dynamic>?)?.map((e) => int.tryParse(e.toString()) ?? 1).toList() ?? [1];
        const dayNames = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
        final names = daysOfWeek.map((d) => dayNames[d] ?? '$d').join(', ');
        return 'Every $names @ $timeStr';
      case 'monthly':
        final daysOfMonth = (frequencyConfig['daysOfMonth'] as List<dynamic>?)?.map((e) => int.tryParse(e.toString()) ?? 1).toList() ?? [1];
        final dayStr = daysOfMonth.map((d) => '$d${_getOrdinal(d)}').join(', ');
        return 'Monthly on $dayStr @ $timeStr';
      case 'custom':
        if (frequencyConfig['customType'] == 'monthdays') {
          final days = (frequencyConfig['daysOfMonth'] as List<dynamic>?)?.map((e) => int.tryParse(e.toString()) ?? 1).toList() ?? [1];
          return 'Custom Monthly: ${days.map((d) => '$d${_getOrdinal(d)}').join(', ')} @ $timeStr';
        } else {
          final days = (frequencyConfig['daysOfWeek'] as List<dynamic>?)?.map((e) => int.tryParse(e.toString()) ?? 1).toList() ?? [1];
          const dayNames = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
          return 'Custom: ${days.map((d) => dayNames[d] ?? '$d').join(', ')} @ $timeStr';
        }
      default:
        return 'Recurring @ $timeStr';
    }
  }

  IconData get frequencyIcon {
    switch (frequencyType) {
      case 'daily':
        return Icons.today_rounded;
      case 'alternate':
        return Icons.swap_horiz_rounded;
      case 'weekly':
        return Icons.date_range_rounded;
      case 'monthly':
        return Icons.calendar_month_rounded;
      case 'custom':
        return Icons.tune_rounded;
      default:
        return Icons.repeat_rounded;
    }
  }

  Color get frequencyColor {
    switch (frequencyType) {
      case 'daily':
        return Colors.blue;
      case 'alternate':
        return Colors.purple;
      case 'weekly':
        return Colors.teal;
      case 'monthly':
        return Colors.indigo;
      case 'custom':
        return Colors.deepOrange;
      default:
        return Colors.orange;
    }
  }

  static String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  FrequentSmsModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? receiverNumber,
    String? message,
    String? simId,
    String? frequencyType,
    Map<String, dynamic>? frequencyConfig,
    String? dispatchTime,
    DateTime? startDate,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    int? totalDispatchedCount,
    String? status,
    DateTime? createdAt,
  }) {
    return FrequentSmsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      receiverNumber: receiverNumber ?? this.receiverNumber,
      message: message ?? this.message,
      simId: simId ?? this.simId,
      frequencyType: frequencyType ?? this.frequencyType,
      frequencyConfig: frequencyConfig ?? this.frequencyConfig,
      dispatchTime: dispatchTime ?? this.dispatchTime,
      startDate: startDate ?? this.startDate,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      totalDispatchedCount: totalDispatchedCount ?? this.totalDispatchedCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    'userId': userId,
    if (title != null) 'title': title,
    'receiverNumber': receiverNumber,
    'message': message,
    'simId': simId,
    'frequencyType': frequencyType,
    'frequencyConfig': frequencyConfig,
    'dispatchTime': dispatchTime,
    'startDate': DateFormat('yyyy-MM-dd').format(startDate),
    'nextRunAt': nextRunAt.toIso8601String(),
    if (lastRunAt != null) 'lastRunAt': lastRunAt!.toIso8601String(),
    'totalDispatchedCount': totalDispatchedCount,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString());
  }

  factory FrequentSmsModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> config = <String, dynamic>{};
    if (json['frequencyConfig'] != null) {
      if (json['frequencyConfig'] is Map) {
        config = Map<String, dynamic>.from(json['frequencyConfig'] as Map);
      }
    }

    return FrequentSmsModel(
      id: _parseInt(json['id']),
      userId: _parseInt(json['userId']) ?? 0,
      title: json['title']?.toString(),
      receiverNumber: json['receiverNumber']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      simId: json['simId']?.toString(),
      frequencyType: json['frequencyType']?.toString() ?? 'daily',
      frequencyConfig: config,
      dispatchTime: json['dispatchTime']?.toString() ?? '09:00',
      startDate: json['startDate'] != null
          ? (DateTime.tryParse(json['startDate'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      nextRunAt: json['nextRunAt'] != null
          ? (DateTime.tryParse(json['nextRunAt'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      lastRunAt: json['lastRunAt'] != null
          ? DateTime.tryParse(json['lastRunAt'].toString())?.toLocal()
          : null,
      totalDispatchedCount: _parseInt(json['totalDispatchedCount']) ?? 0,
      status: json['status']?.toString() ?? 'active',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
