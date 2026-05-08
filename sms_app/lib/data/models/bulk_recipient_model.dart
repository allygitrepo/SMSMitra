enum RecipientStatus { pending, sending, sent, failed }

class BulkRecipientModel {
  final String name;
  final String phone;
  RecipientStatus status;
  String? error;

  BulkRecipientModel({
    required this.name,
    required this.phone,
    this.status = RecipientStatus.pending,
    this.error,
  });
}
