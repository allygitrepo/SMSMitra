/// Model representing an SMS Message Template
class SmsTemplateModel {
  final int? id;
  final int userId;
  final String templateName;
  final String templateMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SmsTemplateModel({
    this.id,
    required this.userId,
    required this.templateName,
    required this.templateMessage,
    this.createdAt,
    this.updatedAt,
  });

  factory SmsTemplateModel.fromJson(Map<String, dynamic> json) {
    return SmsTemplateModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      userId: json['userId'] is int
          ? json['userId'] as int
          : (int.tryParse(json['userId']?.toString() ?? '') ?? 0),
      templateName: json['templateName']?.toString() ?? '',
      templateMessage: json['templateMessage']?.toString() ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'templateName': templateName,
      'templateMessage': templateMessage,
    };
  }

  SmsTemplateModel copyWith({
    int? id,
    int? userId,
    String? templateName,
    String? templateMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmsTemplateModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      templateName: templateName ?? this.templateName,
      templateMessage: templateMessage ?? this.templateMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
