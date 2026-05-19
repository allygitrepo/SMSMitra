import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/organization_model.dart';
import '../../../data/models/template_model.dart';
import '../../../data/models/bulk_recipient_model.dart';
import '../../../data/services/sms_api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/sms_service.dart';
import '../../../data/services/whatsapp_sms_service.dart';
import '../../../core/utils/logger.dart';

class BulkMessagingState {
  final List<OrganizationModel> organizations;
  final List<SmsTemplateModel> templates;
  final OrganizationModel? selectedOrg;
  final SmsTemplateModel? selectedTemplate;
  final List<BulkRecipientModel> recipients;
  final String message;
  final bool isLoading;
  final bool isSending;
  final int sentCount;
  final int failedCount;
  final String channel;
  // final List<TelegramContactModel> telegramContacts;

  BulkMessagingState({
    this.organizations = const [],
    this.templates = const [],
    this.selectedOrg,
    this.selectedTemplate,
    this.recipients = const [],
    this.message = '',
    this.isLoading = false,
    this.isSending = false,
    this.sentCount = 0,
    this.failedCount = 0,
    this.channel = 'sms',
    // this.telegramContacts = const [],
  });

  BulkMessagingState copyWith({
    List<OrganizationModel>? organizations,
    List<SmsTemplateModel>? templates,
    OrganizationModel? selectedOrg,
    SmsTemplateModel? selectedTemplate,
    List<BulkRecipientModel>? recipients,
    String? message,
    bool? isLoading,
    bool? isSending,
    int? sentCount,
    int? failedCount,
    String? channel,
    // List<TelegramContactModel>? telegramContacts,
    bool clearOrg = false,
    bool clearTemplate = false,
  }) {
    return BulkMessagingState(
      organizations: organizations ?? this.organizations,
      templates: templates ?? this.templates,
      selectedOrg: clearOrg ? null : (selectedOrg ?? this.selectedOrg),
      selectedTemplate: clearTemplate ? null : (selectedTemplate ?? this.selectedTemplate),
      recipients: recipients ?? this.recipients,
      message: message ?? this.message,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      sentCount: sentCount ?? this.sentCount,
      failedCount: failedCount ?? this.failedCount,
      channel: channel ?? this.channel,
      // telegramContacts: telegramContacts ?? this.telegramContacts,
    );
  }
}

class BulkMessagingNotifier extends StateNotifier<BulkMessagingState> {
  final _apiService = SmsApiService();
  final _smsService = SmsService();
  final _whatsappService = WhatsAppSmsService();

  BulkMessagingNotifier() : super(BulkMessagingState());

  Future<void> init() async {
    final user = StorageService.getUser();
    if (user == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final orgs = await _apiService.getOrganizations(user.id.toString());
      final templates = await _apiService.getTemplates(user.id.toString());
      state = state.copyWith(
        organizations: orgs,
        templates: templates,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /* Future<void> fetchTelegramContacts() async {
    try {
      final contacts = await TelegramService().getContacts(
        orgCode: state.selectedOrg?.orgCode,
      );
      state = state.copyWith(telegramContacts: contacts);
    } catch (e) {
      logger.e('Failed to fetch telegram contacts: $e');
    }
  } */

  void setChannel(String channel) {
    state = state.copyWith(channel: channel, recipients: []); // clear recipients on channel change
    /* if (channel == 'telegram') {
      fetchTelegramContacts();
    } */
  }

  void selectOrganization(OrganizationModel? org) {
    state = state.copyWith(selectedOrg: org, clearOrg: org == null);
  }

  void selectTemplate(SmsTemplateModel? template) {
    state = state.copyWith(
      selectedTemplate: template,
      message: template?.templateMessage ?? state.message,
      clearTemplate: template == null,
    );
  }

  Future<void> createOrganization({
    required String name,
    String? email,
    String? address,
    File? logo,
  }) async {
    final user = StorageService.getUser();
    if (user == null) return;

    try {
      await _apiService.createOrganization({
        'userId': user.id!,
        'orgName': name,
        'email': email,
        'address': address,
        'logoFile': logo,
      });
      await init(); // Refresh lists
      logger.i("Organization '$name' created.");
    } catch (e) {
      logger.e('Create Org Error: $e');
      rethrow;
    }
  }

  Future<void> createTemplate(String name, String message) async {
    final user = StorageService.getUser();
    if (user == null) return;

    try {
      await _apiService.createTemplate(SmsTemplateModel(
        userId: user.id!,
        templateName: name,
        templateMessage: message,
      ));
      await init(); // Refresh lists
      logger.i("Template '$name' created.");
    } catch (e) {
      logger.e('Create Template Error: $e');
      rethrow;
    }
  }

  void updateMessage(String message) {
    state = state.copyWith(message: message);
  }

  void addRecipient(String name, String phone) {
    // Basic formatting
    if (!phone.startsWith('+')) {
      if (phone.length == 10) {
        phone = '+91$phone';
      } else if (phone.length == 12 && phone.startsWith('91')) {
        phone = '+$phone';
      }
    }

    // Check for duplicates
    if (state.recipients.any((r) => r.phone == phone)) return;

    final newRecipient = BulkRecipientModel(name: name, phone: phone);
    state = state.copyWith(recipients: [...state.recipients, newRecipient]);
  }

  /* void addTelegramRecipient(dynamic contact) {
    if (state.recipients.any((r) => r.phone == contact.telegramChatId)) return;
    
    final newRecipient = BulkRecipientModel(name: contact.name, phone: contact.telegramChatId);
    state = state.copyWith(recipients: [...state.recipients, newRecipient]);
  } */

  void removeRecipient(int index) {
    final newList = List<BulkRecipientModel>.from(state.recipients);
    newList.removeAt(index);
    state = state.copyWith(recipients: newList);
  }

  Future<void> parseFile(String filePath) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _apiService.parseBulkFile(filePath);
      logger.i('Parsed data from server: $data');
      
      final newRecipients = data.map((e) {
        // Find name and phone keys case-insensitively
        String name = 'Guest';
        String phone = '';
        
        e.forEach((key, value) {
          final k = key.toString().toLowerCase().trim();
          if (k == 'name') name = value?.toString() ?? 'Guest';
          if (k == 'phone') phone = value?.toString() ?? '';
        });
        
        return BulkRecipientModel(
          name: name,
          phone: phone,
        );
      }).toList();

      // Merge with existing, avoiding duplicates
      final existingPhones = state.recipients.map((r) => r.phone).toSet();
      final filteredNew = newRecipients.where((r) => r.phone.isNotEmpty && !existingPhones.contains(r.phone)).toList();

      state = state.copyWith(
        recipients: [...state.recipients, ...filteredNew],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void clearRecipients() {
    state = state.copyWith(recipients: []);
  }

  Future<void> downloadTemplate() async {
    try {
      const content = "name,phone\nJohn,9876543210\nRaj,9999999999";
      // In a real app, we'd use path_provider and dart:io to save this file
      // For now, we'll just simulate the success or use a picker
      print("Template Content: $content");
      // Simulate success
    } catch (e) {
      print("Download Template Error: $e");
    }
  }

  Future<void> sendBulkMessages() async {
    if (state.recipients.isEmpty || state.message.isEmpty) return;

    final user = StorageService.getUser();
    if (user == null) return;

    final settings = StorageService.getSettings();
    final simId = settings.activeSimId;

    state = state.copyWith(isSending: true, sentCount: 0, failedCount: 0);

    final recipients = List<BulkRecipientModel>.from(state.recipients);
    
    /* if (state.channel == 'telegram') {
      ...
    } */

    if (state.channel == 'whatsapp') {
      try {
        final waMessages = recipients.map((r) => {
          'number': r.phone,
          'message': state.message.replaceAll('{name}', r.name),
        }).toList();

        // Mark as sending first
        for (var r in recipients) {
          r.status = RecipientStatus.sending;
        }
        state = state.copyWith(recipients: [...recipients]);

        await _whatsappService.sendBulkMessages(
          messages: waMessages,
          sessionId: 'user_1',
          userId: user.id.toString(),
          orgCode: state.selectedOrg?.orgCode,
        );

        // Mark all as sent (successfully queued)
        for (var r in recipients) {
          r.status = RecipientStatus.sent;
        }
        state = state.copyWith(
          recipients: [...recipients],
          sentCount: recipients.length,
          isSending: false,
        );
      } catch (e) {
        // Mark all as failed if the gateway call fails
        for (var r in recipients) {
          r.status = RecipientStatus.failed;
          r.error = e.toString();
        }
        state = state.copyWith(
          recipients: [...recipients],
          failedCount: recipients.length,
          isSending: false,
        );
      }
      return;
    }

    for (int i = 0; i < recipients.length; i++) {
      final recipient = recipients[i];
      recipient.status = RecipientStatus.sending;
      state = state.copyWith(recipients: [...recipients]);

      try {
        final personalizedMsg = state.message.replaceAll('{name}', recipient.name);
        
        final success = await _smsService.sendSms(
          number: recipient.phone,
          message: personalizedMsg,
          simId: simId,
        );

        if (success) {
          recipient.status = RecipientStatus.sent;
          state = state.copyWith(sentCount: state.sentCount + 1);
          
          await _apiService.createManualLog(
            userId: user.id.toString(),
            phoneNumber: recipient.phone,
            message: personalizedMsg,
            status: 'sent',
            simId: simId,
            orgCode: state.selectedOrg?.orgCode,
          );
        } else {
          throw Exception('Failed to send');
        }
      } catch (e) {
        recipient.status = RecipientStatus.failed;
        recipient.error = e.toString();
        state = state.copyWith(failedCount: state.failedCount + 1);

        await _apiService.createManualLog(
          userId: user.id.toString(),
          phoneNumber: recipient.phone,
          message: state.message.replaceAll('{name}', recipient.name),
          status: 'failed',
          simId: simId,
          orgCode: state.selectedOrg?.orgCode,
        );

        if (e.toString().contains('Quota Exceeded')) {
          state = state.copyWith(isSending: false);
          return; // Stop sending if quota exceeded
        }
      }

      state = state.copyWith(recipients: [...recipients]);
      // Small delay between messages to prevent carrier blocking or congestion
      await Future.delayed(const Duration(milliseconds: 500));
    }

    state = state.copyWith(isSending: false);
  }

  void reset() {
    state = BulkMessagingState();
    init(); // Reload orgs and templates
  }
}

final bulkMessagingProvider = StateNotifierProvider<BulkMessagingNotifier, BulkMessagingState>((ref) {
  return BulkMessagingNotifier();
});
