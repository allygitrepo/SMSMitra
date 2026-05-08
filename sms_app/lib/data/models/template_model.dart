class SmsTemplateModel {
  final int? id;
  final int userId;
  final String templateName;
  final String templateMessage;

  SmsTemplateModel({
    this.id,
    required this.userId,
    required this.templateName,
    required this.templateMessage,
  });

  factory SmsTemplateModel.fromJson(Map<String, dynamic> json) => SmsTemplateModel(
    id: json['id'],
    userId: json['userId'],
    templateName: json['templateName'] ?? '',
    templateMessage: json['templateMessage'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'templateName': templateName,
    'templateMessage': templateMessage,
  };
}
