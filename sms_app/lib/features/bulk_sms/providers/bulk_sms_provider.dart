import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/bulk_recipient_model.dart';
import '../../../data/models/template_model.dart';
import '../../../data/services/bulk_sms_service.dart';
import '../../../data/services/sms_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/cache/cache_service.dart';

class BulkSmsState {
  final List<BulkRecipientModel> recipients;
  final List<String> discoveredColumns;
  final String message;
  final SmsTemplateModel? selectedTemplate;
  final String? selectedSimId;
  final int delayMs;
  final bool isParsing;
  final bool isSending;
  final bool isPaused;
  final bool isCancelled;
  final int currentIndex;
  final int sentCount;
  final int failedCount;
  final String? errorMessage;
  final String? summaryMessage;

  const BulkSmsState({
    this.recipients = const [],
    this.discoveredColumns = const ['name', 'phone'],
    this.message = '',
    this.selectedTemplate,
    this.selectedSimId,
    this.delayMs = 600,
    this.isParsing = false,
    this.isSending = false,
    this.isPaused = false,
    this.isCancelled = false,
    this.currentIndex = 0,
    this.sentCount = 0,
    this.failedCount = 0,
    this.errorMessage,
    this.summaryMessage,
  });

  int get totalRecipients => recipients.length;
  double get progress => totalRecipients == 0 ? 0.0 : (currentIndex / totalRecipients).clamp(0.0, 1.0);

  BulkSmsState copyWith({
    List<BulkRecipientModel>? recipients,
    List<String>? discoveredColumns,
    String? message,
    SmsTemplateModel? selectedTemplate,
    bool clearTemplate = false,
    String? selectedSimId,
    int? delayMs,
    bool? isParsing,
    bool? isSending,
    bool? isPaused,
    bool? isCancelled,
    int? currentIndex,
    int? sentCount,
    int? failedCount,
    String? errorMessage,
    String? summaryMessage,
    bool clearError = false,
    bool clearSummary = false,
  }) {
    return BulkSmsState(
      recipients: recipients ?? this.recipients,
      discoveredColumns: discoveredColumns ?? this.discoveredColumns,
      message: message ?? this.message,
      selectedTemplate: clearTemplate ? null : (selectedTemplate ?? this.selectedTemplate),
      selectedSimId: selectedSimId ?? this.selectedSimId,
      delayMs: delayMs ?? this.delayMs,
      isParsing: isParsing ?? this.isParsing,
      isSending: isSending ?? this.isSending,
      isPaused: isPaused ?? this.isPaused,
      isCancelled: isCancelled ?? this.isCancelled,
      currentIndex: currentIndex ?? this.currentIndex,
      sentCount: sentCount ?? this.sentCount,
      failedCount: failedCount ?? this.failedCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      summaryMessage: clearSummary ? null : (summaryMessage ?? this.summaryMessage),
    );
  }
}

class BulkSmsNotifier extends StateNotifier<BulkSmsState> {
  final SmsService _smsService;
  final BulkSmsService _bulkService;

  BulkSmsNotifier({SmsService? smsService, BulkSmsService? bulkService})
      : _smsService = smsService ?? SmsService(),
        _bulkService = bulkService ?? BulkSmsService(),
        super(const BulkSmsState());

  void setMessage(String msg) {
    state = state.copyWith(message: msg);
  }

  void selectTemplate(SmsTemplateModel? template) {
    state = state.copyWith(
      selectedTemplate: template,
      message: template != null ? template.templateMessage : state.message,
      clearTemplate: template == null,
    );
  }

  void setSelectedSim(String? simId) {
    state = state.copyWith(selectedSimId: simId);
  }

  void setDelay(int ms) {
    state = state.copyWith(delayMs: ms);
  }

  /// Inserts a placeholder tag (e.g. `{amount}`) into the controller at the current cursor position
  void insertPlaceholder({
    required String placeholder,
    required TextEditingController controller,
  }) {
    final text = controller.text;
    final selection = controller.selection;
    final tag = '{$placeholder}';

    String newText;
    int newCursorPos;

    if (selection.start >= 0 && selection.end >= 0) {
      newText = text.replaceRange(selection.start, selection.end, tag);
      newCursorPos = selection.start + tag.length;
    } else {
      newText = text + tag;
      newCursorPos = newText.length;
    }

    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: newCursorPos);
    setMessage(newText);
  }

  /// Parses a file path (.csv, .txt) and extracts all custom dynamic columns
  Future<bool> parseFile(String filePath) async {
    state = state.copyWith(isParsing: true, clearError: true);

    try {
      final result = await BulkSmsService.parseFile(filePath);

      if (result.recipients.isEmpty) {
        state = state.copyWith(
          isParsing: false,
          errorMessage: 'No valid phone numbers found in file.',
        );
        return false;
      }

      // Merge discovered columns
      final allCols = <String>{'name', 'phone', ...result.discoveredColumns}.toList();

      state = state.copyWith(
        recipients: result.recipients,
        discoveredColumns: allCols,
        isParsing: false,
        summaryMessage: 'Loaded ${result.recipients.length} recipients (${result.duplicatesRemoved} duplicates removed).',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isParsing: false,
        errorMessage: 'Failed to parse file: $e',
      );
      return false;
    }
  }

  /// Parses raw CSV or phone numbers pasted by the user
  void parseRawText(String rawText) {
    if (rawText.trim().isEmpty) return;

    state = state.copyWith(isParsing: true, clearError: true);

    try {
      final result = BulkSmsService.parseCsvString(rawText);
      final allCols = <String>{'name', 'phone', ...result.discoveredColumns}.toList();

      state = state.copyWith(
        recipients: result.recipients,
        discoveredColumns: allCols,
        isParsing: false,
        summaryMessage: 'Imported ${result.recipients.length} recipients.',
      );
    } catch (e) {
      state = state.copyWith(
        isParsing: false,
        errorMessage: 'Error parsing text: $e',
      );
    }
  }

  /// Adds a single manual recipient
  void addManualRecipient(String phone, String name, [Map<String, String>? customData]) {
    final formatted = BulkSmsService.formatPhoneNumber(phone);
    if (formatted.replaceAll('+', '').length < 8) {
      state = state.copyWith(errorMessage: 'Invalid phone number format.');
      return;
    }

    // Check duplicate
    if (state.recipients.any((r) => r.phone == formatted)) {
      state = state.copyWith(errorMessage: 'Recipient $formatted already in list.');
      return;
    }

    final newRecipient = BulkRecipientModel(
      phone: formatted,
      name: name.trim(),
      customData: customData ?? {},
    );

    final updatedCols = <String>{'name', 'phone', ...state.discoveredColumns, ...?(customData?.keys)}.toList();

    state = state.copyWith(
      recipients: [...state.recipients, newRecipient],
      discoveredColumns: updatedCols,
      clearError: true,
    );
  }

  void removeRecipient(int index) {
    if (index < 0 || index >= state.recipients.length) return;
    final updated = List<BulkRecipientModel>.from(state.recipients)..removeAt(index);
    state = state.copyWith(recipients: updated);
  }

  void clearRecipients() {
    state = state.copyWith(
      recipients: [],
      currentIndex: 0,
      sentCount: 0,
      failedCount: 0,
      clearSummary: true,
      clearError: true,
    );
  }

  void pauseSending() {
    state = state.copyWith(isPaused: true);
  }

  void resumeSending() {
    state = state.copyWith(isPaused: false);
  }

  void cancelSending() {
    state = state.copyWith(isCancelled: true, isSending: false);
  }

  /// Starts throttled sequential SMS dispatching over physical Android SIM cards
  Future<void> startSending({required VoidCallback onComplete}) async {
    if (state.recipients.isEmpty || state.message.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please provide recipients and message content.');
      return;
    }

    final user = StorageService.getUser();
    final userId = user?.id ?? 0;

    // Reset progress counters
    state = state.copyWith(
      isSending: true,
      isPaused: false,
      isCancelled: false,
      currentIndex: 0,
      sentCount: 0,
      failedCount: 0,
      clearError: true,
      clearSummary: true,
    );

    final updatedRecipients = List<BulkRecipientModel>.from(state.recipients);

    for (int i = 0; i < updatedRecipients.length; i++) {
      if (state.isCancelled) break;

      // Handle pause loop
      while (state.isPaused) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (state.isCancelled) break;
      }
      if (state.isCancelled) break;

      final recipient = updatedRecipients[i];
      final personalizedMsg = recipient.interpolateMessage(state.message);

      // Mark status as sending
      updatedRecipients[i] = recipient.copyWith(status: BulkSendStatus.sending);
      state = state.copyWith(
        currentIndex: i + 1,
        recipients: updatedRecipients,
      );

      try {
        final success = await _smsService.sendSms(
          number: recipient.phone,
          message: personalizedMsg,
          simId: state.selectedSimId,
        );

        if (success) {
          updatedRecipients[i] = recipient.copyWith(status: BulkSendStatus.sent);
          state = state.copyWith(
            sentCount: state.sentCount + 1,
            recipients: updatedRecipients,
          );
          await CacheService().incrementSentStats();
          unawaited(
            _bulkService.logDispatchedSms(
              userId: userId,
              phoneNumber: recipient.phone,
              message: personalizedMsg,
              simId: state.selectedSimId,
              status: 'sent',
            ),
          );
        } else {
          updatedRecipients[i] = recipient.copyWith(
            status: BulkSendStatus.failed,
            errorMessage: 'Carrier send failed',
          );
          state = state.copyWith(
            failedCount: state.failedCount + 1,
            recipients: updatedRecipients,
          );
          unawaited(
            _bulkService.logDispatchedSms(
              userId: userId,
              phoneNumber: recipient.phone,
              message: personalizedMsg,
              simId: state.selectedSimId,
              status: 'failed',
              errorMessage: 'Carrier send failed',
            ),
          );
        }
      } catch (e) {
        updatedRecipients[i] = recipient.copyWith(
          status: BulkSendStatus.failed,
          errorMessage: e.toString(),
        );
        state = state.copyWith(
          failedCount: state.failedCount + 1,
          recipients: updatedRecipients,
        );
        unawaited(
          _bulkService.logDispatchedSms(
            userId: userId,
            phoneNumber: recipient.phone,
            message: personalizedMsg,
            simId: state.selectedSimId,
            status: 'failed',
            errorMessage: e.toString(),
          ),
        );
      }

      // Throttling delay between sends to protect carrier SIM queue
      if (i < updatedRecipients.length - 1 && state.delayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: state.delayMs));
      }
    }

    state = state.copyWith(
      isSending: false,
      summaryMessage: 'Campaign finished: ${state.sentCount} sent, ${state.failedCount} failed.',
    );

    onComplete();
  }
}

final bulkSmsProvider = StateNotifierProvider<BulkSmsNotifier, BulkSmsState>((ref) {
  return BulkSmsNotifier();
});
