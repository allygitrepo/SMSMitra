import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/helpers/validation_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/frequent_sms_model.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../home/stats_provider.dart';
import '../../bulk_sms/widgets/templates_sheet.dart';
import '../../contacts/widgets/contact_picker_sheet.dart';
import '../frequent_provider.dart';

class FrequentSmsSheet extends ConsumerStatefulWidget {
  final FrequentSmsModel? ruleToEdit;

  const FrequentSmsSheet({super.key, this.ruleToEdit});

  static Future<bool?> show(BuildContext context, {FrequentSmsModel? ruleToEdit}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FrequentSmsSheet(ruleToEdit: ruleToEdit),
    );
  }

  @override
  ConsumerState<FrequentSmsSheet> createState() => _FrequentSmsSheetState();
}

class _FrequentSmsSheetState extends ConsumerState<FrequentSmsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _phoneController;
  late final TextEditingController _messageController;

  String? _selectedSimId;
  String _frequencyType = 'daily'; // 'daily', 'alternate', 'weekly', 'monthly', 'custom'
  String _alternateStart = 'today'; // 'today', 'tomorrow'
  List<int> _selectedWeekdays = [1]; // 1=Mon, ..., 7=Sun
  List<int> _selectedMonthDays = [1]; // 1..31
  String _customType = 'weekdays'; // 'weekdays', 'monthdays'
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.ruleToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _phoneController = TextEditingController(text: edit?.receiverNumber ?? '');
    _messageController = TextEditingController(text: edit?.message ?? '');
    _selectedSimId = edit?.simId;

    if (edit != null) {
      _frequencyType = edit.frequencyType;
      final config = edit.frequencyConfig;
      if (config['startFrom'] != null) {
        _alternateStart = config['startFrom'].toString();
      }
      if (config['daysOfWeek'] != null && config['daysOfWeek'] is List) {
        _selectedWeekdays = (config['daysOfWeek'] as List).map((e) => int.tryParse(e.toString()) ?? 1).toList();
      }
      if (config['daysOfMonth'] != null && config['daysOfMonth'] is List) {
        _selectedMonthDays = (config['daysOfMonth'] as List).map((e) => int.tryParse(e.toString()) ?? 1).toList();
      }
      if (config['customType'] != null) {
        _customType = config['customType'].toString();
      }

      final parts = edit.dispatchTime.split(':');
      final h = int.tryParse(parts[0]) ?? 9;
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
      _selectedTime = TimeOfDay(hour: h, minute: m);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final temp = DateTime(2026, 1, 1, time.hour, time.minute);
    return DateFormat('hh:mm a').format(temp);
  }

  String _to24HourString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context) async {
    DateTime tempTime = DateTime(2026, 1, 1, _selectedTime.hour, _selectedTime.minute);

    final selected = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: 280,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Dispatch Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(ctx).textTheme.bodyLarge?.color,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx, TimeOfDay(hour: tempTime.hour, minute: tempTime.minute));
                        },
                        child: const Text('Done', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: tempTime,
                    use24hFormat: false,
                    onDateTimeChanged: (newDateTime) {
                      tempTime = newDateTime;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedTime = selected;
      });
    }
  }

  Map<String, dynamic> _buildFrequencyConfig() {
    switch (_frequencyType) {
      case 'alternate':
        return <String, dynamic>{'startFrom': _alternateStart};
      case 'weekly':
        return <String, dynamic>{'daysOfWeek': _selectedWeekdays};
      case 'monthly':
        return <String, dynamic>{'daysOfMonth': _selectedMonthDays};
      case 'custom':
        return <String, dynamic>{
          'customType': _customType,
          if (_customType == 'weekdays') 'daysOfWeek': _selectedWeekdays,
          if (_customType == 'monthdays') 'daysOfMonth': _selectedMonthDays,
        };
      default:
        return <String, dynamic>{};
    }
  }

  String _getFrequencyPreviewText() {
    final timeStr = _formatTimeOfDay(_selectedTime);
    switch (_frequencyType) {
      case 'daily':
        return 'Dispatches every day at $timeStr';
      case 'alternate':
        return 'Dispatches every alternate day (Starting ${_alternateStart == 'tomorrow' ? 'Tomorrow' : 'Today'}) at $timeStr';
      case 'weekly': {
        const dayNames = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
        final days = _selectedWeekdays.map((d) => dayNames[d] ?? '$d').join(', ');
        return 'Dispatches every $days at $timeStr';
      }
      case 'monthly': {
        final days = _selectedMonthDays.map((d) => '$d${_getOrdinal(d)}').join(', ');
        return 'Dispatches on $days of every month at $timeStr';
      }
      case 'custom': {
        if (_customType == 'monthdays') {
          final days = _selectedMonthDays.map((d) => '$d${_getOrdinal(d)}').join(', ');
          return 'Custom: Monthly on $days at $timeStr';
        } else {
          const dayNames = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
          final days = _selectedWeekdays.map((d) => dayNames[d] ?? '$d').join(', ');
          return 'Custom: Every $days at $timeStr';
        }
      }
      default:
        return 'Recurring SMS at $timeStr';
    }
  }

  static String _getOrdinal(int n) {
    if (n >= 11 && n <= 13) return 'th';
    switch (n % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_frequencyType == 'weekly' && _selectedWeekdays.isEmpty) {
      MessageHelper.showError(context, 'Please select at least one weekday.');
      return;
    }

    if (_frequencyType == 'monthly' && _selectedMonthDays.isEmpty) {
      MessageHelper.showError(context, 'Please select at least one day of the month.');
      return;
    }

    final phone = _phoneController.text.trim();
    final message = _messageController.text.trim();
    final title = _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null;
    final dispatchTime = _to24HourString(_selectedTime);
    final config = _buildFrequencyConfig();

    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);

    // Dismiss bottom sheet immediately so timeline / space-making animations play live!
    navigator.pop(true);

    if (widget.ruleToEdit != null) {
      final success = await ref.read(frequentProvider.notifier).updateRule(
        id: widget.ruleToEdit!.id!,
        title: title,
        receiverNumber: phone,
        message: message,
        simId: _selectedSimId,
        frequencyType: _frequencyType,
        frequencyConfig: config,
        dispatchTime: dispatchTime,
      );

      if (mounted && !success) {
        MessageHelper.showError(context, 'Failed to update recurring rule');
      }
    } else {
      final success = await ref.read(frequentProvider.notifier).createRule(
        title: title,
        receiverNumber: phone,
        message: message,
        simId: _selectedSimId,
        frequencyType: _frequencyType,
        frequencyConfig: config,
        dispatchTime: dispatchTime,
      );

      if (mounted && !success) {
        MessageHelper.showError(context, 'Failed to create recurring rule');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final simsAsync = ref.watch(simsProvider);
    final isEditing = widget.ruleToEdit != null;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Drag Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.repeat_rounded, color: AppColors.orange, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Recurring SMS' : 'Frequently Sending SMS',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isEditing
                              ? 'Update automated recurrence rules'
                              : 'Set automatic periodic SMS dispatch',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Campaign / Rule Title (Optional)
                CustomTextField(
                  label: 'Rule Name / Label (Optional)',
                  hint: 'e.g. Daily Stock Summary, Weekly Reminder',
                  icon: Icons.label_outline_rounded,
                  controller: _titleController,
                ),
                const SizedBox(height: AppSpacing.md),

                // Recipient Number
                CustomTextField(
                  label: 'Recipient Mobile Number',
                  hint: 'Enter 10-digit mobile number',
                  icon: Icons.phone_android_rounded,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
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
                        if (_titleController.text.isEmpty) {
                          _titleController.text = '${contact.name} Reminder';
                        }
                      });
                      MessageHelper.showSuccess(context, 'Selected ${contact.name}');
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Message Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'SMS Message Template',
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
                      ValidationHelper.validateNotEmpty(val, 'Message template'),
                  decoration: InputDecoration(
                    hintText: 'Type message to send periodically...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 32),
                      child: Icon(Icons.message_outlined, size: 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Gateway SIM Card Selector
                const Text(
                  'Dispatch Gateway SIM',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.xs),
                simsAsync.when(
                  data: (sims) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Auto Priority SIM'),
                            selected: _selectedSimId == null,
                            selectedColor: AppColors.orange.withValues(alpha: 0.2),
                            onSelected: (_) => setState(() => _selectedSimId = null),
                          ),
                          ...sims.map((sim) {
                            final isSelected = _selectedSimId == sim.id;
                            return Padding(
                              padding: const EdgeInsets.only(left: AppSpacing.xs),
                              child: ChoiceChip(
                                avatar: Icon(
                                  Icons.sim_card_outlined,
                                  size: 16,
                                  color: isSelected ? AppColors.orange : Colors.grey,
                                ),
                                label: Text('${sim.carrierName} (Slot ${sim.slotIndex})'),
                                selected: isSelected,
                                selectedColor: AppColors.orange.withValues(alpha: 0.2),
                                onSelected: (_) => setState(() => _selectedSimId = sim.id),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(height: 38, child: LinearProgressIndicator()),
                  error: (_, __) => const Text('Unable to detect SIM cards', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Frequency Type Selector (Daily, Alternate Day, Weekly, Monthly, Custom)
                const Text(
                  'Recurrence Frequency',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFrequencyChip('Daily', 'daily', Icons.today_rounded),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFrequencyChip('Alternate Day', 'alternate', Icons.swap_horiz_rounded),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFrequencyChip('Weekly', 'weekly', Icons.date_range_rounded),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFrequencyChip('Monthly', 'monthly', Icons.calendar_month_rounded),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFrequencyChip('Custom', 'custom', Icons.tune_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Sub-Selector options based on frequency type
                _buildSubSelector(theme),
                const SizedBox(height: AppSpacing.md),

                // Time Selection Row
                const Text(
                  'Daily Dispatch Time',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.xs),
                InkWell(
                  onTap: () => _selectTime(context),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: AppColors.orange, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              _formatTimeOfDay(_selectedTime),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const Row(
                          children: [
                            Text('Change', style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.orange),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Live Frequency Summary Preview Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.orange, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _getFrequencyPreviewText(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                GradientButton(
                  text: isEditing ? 'Update Recurring Rule' : 'Save Recurring Rule',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyChip(String label, String value, IconData icon) {
    final isSelected = _frequencyType == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.orange,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _frequencyType = value),
    );
  }

  Widget _buildSubSelector(ThemeData theme) {
    switch (_frequencyType) {
      case 'alternate':
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Start Alternate Cycle From:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Start from Today')),
                      selected: _alternateStart == 'today',
                      selectedColor: AppColors.orange.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _alternateStart = 'today'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Start from Tomorrow')),
                      selected: _alternateStart == 'tomorrow',
                      selectedColor: AppColors.orange.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _alternateStart = 'tomorrow'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      case 'weekly':
        return _buildWeekdayPicker(theme);

      case 'monthly':
        return _buildMonthDayPicker(theme);

      case 'custom':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Custom Weekdays')),
                    selected: _customType == 'weekdays',
                    selectedColor: AppColors.orange.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _customType = 'weekdays'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Custom Month Days')),
                    selected: _customType == 'monthdays',
                    selectedColor: AppColors.orange.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _customType = 'monthdays'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _customType == 'weekdays' ? _buildWeekdayPicker(theme) : _buildMonthDayPicker(theme),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWeekdayPicker(ThemeData theme) {
    const days = [
      {'id': 1, 'name': 'M', 'label': 'Mon'},
      {'id': 2, 'name': 'T', 'label': 'Tue'},
      {'id': 3, 'name': 'W', 'label': 'Wed'},
      {'id': 4, 'name': 'T', 'label': 'Thu'},
      {'id': 5, 'name': 'F', 'label': 'Fri'},
      {'id': 6, 'name': 'S', 'label': 'Sat'},
      {'id': 7, 'name': 'S', 'label': 'Sun'},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Days of the Week:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((day) {
              final id = day['id'] as int;
              final isSelected = _selectedWeekdays.contains(id);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      if (_selectedWeekdays.length > 1) {
                        _selectedWeekdays.remove(id);
                      }
                    } else {
                      _selectedWeekdays.add(id);
                      _selectedWeekdays.sort();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.orange : theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? AppColors.orange : theme.dividerColor),
                  ),
                  child: Center(
                    child: Text(
                      day['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDayPicker(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Month Dates (1 to 31):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(31, (index) {
              final day = index + 1;
              final isSelected = _selectedMonthDays.contains(day);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      if (_selectedMonthDays.length > 1) {
                        _selectedMonthDays.remove(day);
                      }
                    } else {
                      _selectedMonthDays.add(day);
                      _selectedMonthDays.sort();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.orange : theme.cardColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? AppColors.orange : theme.dividerColor),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
