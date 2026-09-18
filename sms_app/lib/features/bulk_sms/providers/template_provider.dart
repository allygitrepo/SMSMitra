import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/template_model.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/template_service.dart';

class TemplateState {
  final List<SmsTemplateModel> templates;
  final bool isLoading;
  final bool isCreating;
  final String? errorMessage;
  final String? successMessage;

  const TemplateState({
    this.templates = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.errorMessage,
    this.successMessage,
  });

  TemplateState copyWith({
    List<SmsTemplateModel>? templates,
    bool? isLoading,
    bool? isCreating,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TemplateState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class TemplateNotifier extends StateNotifier<TemplateState> {
  final TemplateService _service;

  TemplateNotifier({TemplateService? service})
      : _service = service ?? TemplateService(),
        super(const TemplateState()) {
    fetchTemplates();
  }

  Future<void> fetchTemplates({bool silent = false}) async {
    final user = StorageService.getUser();
    if (user == null || user.id == null) return;

    if (!silent && state.templates.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final list = await _service.getTemplates(user.id!);
      state = state.copyWith(
        templates: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load templates: $e',
      );
    }
  }

  Future<bool> createTemplate({
    required String name,
    required String message,
  }) async {
    final user = StorageService.getUser();
    if (user == null || user.id == null) return false;

    state = state.copyWith(isCreating: true, clearError: true);

    try {
      final newTemplate = await _service.createTemplate(
        SmsTemplateModel(
          userId: user.id!,
          templateName: name.trim(),
          templateMessage: message.trim(),
        ),
      );

      state = state.copyWith(
        templates: [newTemplate, ...state.templates],
        isCreating: false,
        successMessage: 'Template created successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: 'Failed to create template: $e',
      );
      return false;
    }
  }

  Future<bool> updateTemplate({
    required int id,
    required String name,
    required String message,
  }) async {
    final user = StorageService.getUser();
    if (user == null || user.id == null) return false;

    try {
      final updated = await _service.updateTemplate(
        SmsTemplateModel(
          id: id,
          userId: user.id!,
          templateName: name.trim(),
          templateMessage: message.trim(),
        ),
      );

      state = state.copyWith(
        templates: state.templates.map((t) => t.id == id ? updated : t).toList(),
        successMessage: 'Template updated successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update template: $e');
      return false;
    }
  }

  Future<bool> deleteTemplate(int id) async {
    try {
      final success = await _service.deleteTemplate(id);
      if (success) {
        state = state.copyWith(
          templates: state.templates.where((t) => t.id != id).toList(),
          successMessage: 'Template deleted',
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete template: $e');
      return false;
    }
  }
}

final templateProvider = StateNotifierProvider<TemplateNotifier, TemplateState>((ref) {
  return TemplateNotifier();
});
