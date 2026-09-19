import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sms_app/data/models/scheduled_sms_model.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/helpers/validation_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../home/stats_provider.dart';
import '../../settings/settings_provider.dart';
import '../../bulk_sms/widgets/templates_sheet.dart';
import '../../contacts/widgets/contact_picker_sheet.dart';
import '../schedules_provider.dart';

class ScheduleSmsSheet extends ConsumerStatefulWidget {
  final ScheduledSmsModel? scheduleToEdit;

  const ScheduleSmsSheet({super.key, this.scheduleToEdit});

  static Future<bool?> show(BuildContext context,
      {ScheduledSmsModel? scheduleToEdit}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleSmsSheet(scheduleToEdit: scheduleToEdit),
    );
  }

  @override
  ConsumerState<ScheduleSmsSheet> createState() => _ScheduleSmsSheetState();
}

class _ScheduleSmsSheetState extends ConsumerState<ScheduleSmsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedSimId;

  @override
  void initState() {
    super.initState();
    final edit = widget.scheduleToEdit;
    if (edit != null) {
      final localTime = edit.scheduledAt.toLocal();
      _phoneController.text = edit.receiverNumber;
      _messageController.text = edit.message;
      _selectedSimId = edit.simId;
      _selectedDate = DateTime(localTime.year, localTime.month, localTime.day);
      _selectedTime = TimeOfDay(hour: localTime.hour, minute: localTime.minute);
    } else {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = TimeOfDay.fromDateTime(now.add(const Duration(minutes: 5)));
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  DateTime get _combinedScheduledDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.orange,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                    secondary: AppColors.orange,
                  )
                : const ColorScheme.light(
                    primary: AppColors.orange,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                    secondary: AppColors.orange,
                  ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              headerBackgroundColor: AppColors.orange,
              headerForegroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return Colors.grey.withValues(alpha: 0.3);
                }
                return isDark ? Colors.white : Colors.black87;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.orange;
                }
                return null;
              }),
              todayForegroundColor:
                  const WidgetStatePropertyAll(AppColors.orange),
              todayBorder:
                  const BorderSide(color: AppColors.orange, width: 1.5),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickTime() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    DateTime tempDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height: 320,
                child: Column(
                  children: [
                    // Header Bar with Cancel & Done
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(bottomSheetContext),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            'Select Time',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(bottomSheetContext, tempDateTime),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Scroll wheel time picker
                    Expanded(
                      child: CupertinoTheme(
                        data: CupertinoThemeData(
                          brightness:
                              isDark ? Brightness.dark : Brightness.light,
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          use24hFormat: false,
                          initialDateTime: tempDateTime,
                          onDateTimeChanged: (DateTime newDateTime) {
                            tempDateTime = newDateTime;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedTime = TimeOfDay(hour: result.hour, minute: result.minute);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final targetDateTime = _combinedScheduledDateTime;
    if (targetDateTime.isBefore(DateTime.now())) {
      MessageHelper.showError(
        context,
        'Scheduled time must be in the future.',
      );
      return;
    }

    final isEditing = widget.scheduleToEdit != null;
    final phone = _phoneController.text.trim();
    final message = _messageController.text.trim();
    final simId = _selectedSimId;
    final editId = widget.scheduleToEdit?.id;
    final notifier = ref.read(schedulesProvider.notifier);

    // Dismiss bottom sheet immediately so the user directly witnesses the timeline space-making animation
    Navigator.pop(context, true);

    if (isEditing && editId != null) {
      unawaited(notifier.updateSchedule(
        id: editId,
        receiverNumber: phone,
        message: message,
        simId: simId,
        scheduledAt: targetDateTime,
      ));
    } else {
      unawaited(notifier.createSchedule(
        receiverNumber: phone,
        message: message,
        simId: simId,
        scheduledAt: targetDateTime,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final simsAsync = ref.watch(simsProvider);
    final settings = ref.watch(settingsProvider);
    final schedulesState = ref.watch(schedulesProvider);

    final isEditing = widget.scheduleToEdit != null;
    final scheduledDateTime = _combinedScheduledDateTime;
    final isFutureValid = scheduledDateTime.isAfter(DateTime.now());

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_calendar_rounded
                          : Icons.schedule_send_rounded,
                      color: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Scheduled SMS' : 'Schedule SMS',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isEditing
                              ? 'Modify dispatch details and target time'
                              : 'Automate dispatch at a future date and time',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Phone Field
              CustomTextField(
                controller: _phoneController,
                label: 'Receiver Mobile Number',
                hint: 'e.g. 9876543210',
                icon: Icons.phone_android_rounded,
                keyboardType: TextInputType.phone,
                validator: ValidationHelper.validatePhone,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.contacts_rounded, color: AppColors.orange, size: 20),
                  tooltip: 'Select from Contacts',
                  onPressed: () async {
                    final contact = await ContactPickerSheet.showSingle(context);
                    if (contact == null || !context.mounted) return;
                    final raw = contact.phone.replaceAll(RegExp(r'[^0-9]'), '');
                    final phone10 = raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
                    setState(() {
                      _phoneController.text = phone10;
                    });
                    MessageHelper.showSuccess(context, 'Selected ${contact.name}');
                  },
                ),
              ),

              // SIM Selection Dropdown
              simsAsync.when(
                data: (sims) {
                  final activeSimId = _selectedSimId ??
                      settings.activeSimId ??
                      (sims.isNotEmpty ? sims.first.id : null);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Outbound SIM Gateway',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: activeSimId,
                            isExpanded: true,
                            icon: const Icon(Icons.sim_card_outlined,
                                color: AppColors.orange),
                            hint: const Text('Select Outbound SIM'),
                            items: sims.map((sim) {
                              return DropdownMenuItem<String>(
                                value: sim.id,
                                child: Text(
                                  '${sim.carrierName} (${sim.number.isNotEmpty ? sim.number : 'Slot ${sim.slotIndex + 1}'})',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedSimId = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Date & Time Pickers
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Schedule Date & Time',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppColors.orange),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Date',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  Text(
                                    DateFormat('dd MMM yyyy')
                                        .format(_selectedDate),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 18, color: AppColors.orange),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Time',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  Text(
                                    _selectedTime.format(context),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!isFutureValid) ...[
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Selected time must be in the future',
                  style: TextStyle(fontSize: 11, color: Colors.red),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // Message Body Field
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'Message Body',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => TemplatesSheet.show(
                      context,
                      onSelect: (template) {
                        setState(() {
                          _messageController.text = template.templateMessage;
                        });
                      },
                    ),
                    icon: const Icon(Icons.bookmark_outline_rounded, size: 15, color: AppColors.orange),
                    label: const Text(
                      'Use Template',
                      style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _messageController,
                maxLines: 3,
                validator: (val) =>
                    ValidationHelper.validateNotEmpty(val, 'Message body'),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Type scheduled message content...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 32),
                    child: Icon(Icons.message_outlined, size: 20),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${_messageController.text.length} chars (${(_messageController.text.length / 160).ceil()} SMS)',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              GradientButton(
                text: isEditing ? 'Save Changes' : 'Schedule Outbound SMS',
                isLoading: schedulesState.isCreating,
                onPressed: isFutureValid ? _handleSubmit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
