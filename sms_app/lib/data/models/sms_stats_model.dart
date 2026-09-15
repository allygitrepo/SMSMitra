/// Immutable model representing real-time daily SMS statistics.
class SmsStatsModel {
  final int sentToday;
  final int failedToday;
  final bool isLoading;
  final String? errorMessage;

  const SmsStatsModel({
    this.sentToday = 0,
    this.failedToday = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  SmsStatsModel copyWith({
    int? sentToday,
    int? failedToday,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SmsStatsModel(
      sentToday: sentToday ?? this.sentToday,
      failedToday: failedToday ?? this.failedToday,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsStatsModel &&
          runtimeType == other.runtimeType &&
          sentToday == other.sentToday &&
          failedToday == other.failedToday &&
          isLoading == other.isLoading &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      sentToday.hashCode ^
      failedToday.hashCode ^
      isLoading.hashCode ^
      (errorMessage?.hashCode ?? 0);
}
