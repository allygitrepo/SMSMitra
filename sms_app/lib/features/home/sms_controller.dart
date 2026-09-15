import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/sms_repository.dart';
import '../../core/errors/app_exceptions.dart';

enum SmsSendStatus { initial, sending, success, failure }

class SmsState {
  final SmsSendStatus status;
  final String? errorMessage;
  final String? successMessage;

  const SmsState({
    this.status = SmsSendStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  bool get isSending => status == SmsSendStatus.sending;

  SmsState copyWith({
    SmsSendStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return SmsState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final smsControllerProvider = StateNotifierProvider<SmsController, SmsState>((ref) {
  final repository = ref.watch(smsRepositoryProvider);
  return SmsController(repository);
});

/// Riverpod Controller managing Quick SMS state and actions.
class SmsController extends StateNotifier<SmsState> {
  final SmsRepository _repository;

  SmsController(this._repository) : super(const SmsState());

  Future<bool> sendQuickSms({
    required String phone,
    required String message,
  }) async {
    state = state.copyWith(status: SmsSendStatus.sending, errorMessage: null);

    try {
      await _repository.sendSms(
        phoneNumber: phone,
        message: message,
      );

      state = state.copyWith(
        status: SmsSendStatus.success,
        successMessage: 'SMS dispatched successfully!',
      );
      return true;
    } on AppException catch (e) {
      state = state.copyWith(
        status: SmsSendStatus.failure,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: SmsSendStatus.failure,
        errorMessage: 'An unexpected error occurred while sending SMS.',
      );
      return false;
    }
  }

  void resetState() {
    state = const SmsState();
  }
}
