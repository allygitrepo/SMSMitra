enum BulkSendStatus {
  pending,
  sending,
  sent,
  failed,
}

/// Model representing a recipient in a Bulk SMS campaign with dynamic multi-column support
class BulkRecipientModel {
  final String phone;
  final String name;
  final Map<String, String> customData;
  final BulkSendStatus status;
  final String? errorMessage;

  const BulkRecipientModel({
    required this.phone,
    this.name = '',
    this.customData = const {},
    this.status = BulkSendStatus.pending,
    this.errorMessage,
  });

  /// Interpolates a message template by replacing {name} and all dynamic {customField} tags
  String interpolateMessage(String template) {
    String message = template;

    // Replace all dynamic custom column placeholders
    customData.forEach((key, value) {
      // Replace both {key} and {Key} and {KEY} case-insensitively
      final regex = RegExp('\\{${RegExp.escape(key)}\\}', caseSensitive: false);
      message = message.replaceAll(regex, value);
    });

    // Explicit fallback for {name}
    final nameRegex = RegExp(r'\{name\}', caseSensitive: false);
    if (name.trim().isNotEmpty) {
      message = message.replaceAll(nameRegex, name.trim());
    } else if (customData.containsKey('name') && customData['name']!.isNotEmpty) {
      message = message.replaceAll(nameRegex, customData['name']!);
    } else {
      message = message.replaceAll(nameRegex, 'User');
    }

    // Explicit fallback for {phone}
    final phoneRegex = RegExp(r'\{phone\}', caseSensitive: false);
    message = message.replaceAll(phoneRegex, phone);

    return message;
  }

  BulkRecipientModel copyWith({
    String? phone,
    String? name,
    Map<String, String>? customData,
    BulkSendStatus? status,
    String? errorMessage,
  }) {
    return BulkRecipientModel(
      phone: phone ?? this.phone,
      name: name ?? this.name,
      customData: customData ?? this.customData,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory BulkRecipientModel.fromJson(Map<String, dynamic> json) {
    final phone = (json['phone'] ?? json['phoneNumber'] ?? json['mobile'] ?? '').toString();
    final name = (json['name'] ?? json['fullName'] ?? '').toString();
    final customData = <String, String>{};

    json.forEach((key, value) {
      if (key != 'phone' && key != 'phoneNumber' && key != 'mobile' && key != 'status' && key != 'errorMessage') {
        customData[key] = value?.toString() ?? '';
      }
    });

    return BulkRecipientModel(
      phone: phone,
      name: name,
      customData: customData,
      status: BulkSendStatus.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'name': name,
      ...customData,
      'status': status.name,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }
}
