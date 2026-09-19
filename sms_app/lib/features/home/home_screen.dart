import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/helpers/validation_helper.dart';
import '../../core/helpers/snackbar_helper.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/confirm_bottom_sheet.dart';
import '../settings/settings_provider.dart';
import '../bulk_sms/widgets/templates_sheet.dart';
import '../contacts/widgets/contact_picker_sheet.dart';
import '../profile/profile_screen.dart';
import '../../data/providers/user_provider.dart';
import 'stats_provider.dart';
import 'sms_controller.dart';
import '../../data/services/socket_service.dart';

/// The main operational screen of the app where users send SMS.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _messageFocus = FocusNode();
  String? _selectedContactName;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  StreamSubscription<void>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());

    // Listen for real-time stats updates from server
    _fcmSubscription = FirebaseMessaging.onMessage.listen((message) {
      if (message.data['type'] == 'STATS_UPDATE') {
        _refreshData();
      }
    });

    SocketService().initSocket();
    _socketSubscription = SocketService().statsUpdateStream.listen((_) {
      _refreshData();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    await ref.read(smsStatsProvider.notifier).fetchStats();
    // ignore: unused_result
    await ref.refresh(simsProvider.future);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fcmSubscription?.cancel();
    _socketSubscription?.cancel();
    SocketService().disconnect();
    _phoneController.dispose();
    _messageController.dispose();
    _phoneFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _insertTextIntoMessage(String textToInsert) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    String newText;
    int newPos;

    if (selection.start >= 0 && selection.end >= 0) {
      newText = text.replaceRange(selection.start, selection.end, textToInsert);
      newPos = selection.start + textToInsert.length;
    } else {
      final needsSpace = text.isNotEmpty && !text.endsWith(' ');
      newText = text + (needsSpace ? ' ' : '') + textToInsert;
      newPos = newText.length;
    }

    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(offset: newPos);
  }

  void _showEditContactNameDialog() {
    final controller = TextEditingController(text: _selectedContactName);
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Edit Contact Name',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Contact Name',
            hintText: 'Enter name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              Navigator.pop(dialogCtx);
              setState(() {
                _selectedContactName = newName.isNotEmpty ? newName : null;
              });
              if (newName.isNotEmpty && mounted) {
                MessageHelper.showSuccess(
                    context, 'Updated contact name: $newName');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    if (_formKey.currentState!.validate()) {
      final phone = _phoneController.text.trim();
      var message = _messageController.text.trim();

      // If message contains {name} tag and name is provided, dynamically interpolate it
      if (_selectedContactName != null && _selectedContactName!.isNotEmpty) {
        message = message.replaceAll(
            RegExp(r'\{\s*name\s*\}', caseSensitive: false),
            _selectedContactName!);
      }

      final success =
          await ref.read(smsControllerProvider.notifier).sendQuickSms(
                phone: phone,
                message: message,
              );

      if (!mounted) return;

      final smsState = ref.read(smsControllerProvider);
      if (success) {
        final target =
            (_selectedContactName != null && _selectedContactName!.isNotEmpty)
                ? '$_selectedContactName ($phone)'
                : phone;
        MessageHelper.showSuccess(context, 'SMS dispatched to $target');
        _messageController.clear();
      } else {
        MessageHelper.showError(
            context, smsState.errorMessage ?? 'Failed to send SMS');
      }
    }
  }

  Future<bool> _showExitBottomSheet() async {
    return await ConfirmBottomSheet.show(
      context,
      icon: Icons.exit_to_app_rounded,
      title: 'Exit Application?',
      message: 'Are you sure you want to close SMS Mitra?',
      confirmLabel: 'Exit',
      confirmColor: Colors.orange,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final stats = ref.watch(smsStatsProvider);
    final simsAsync = ref.watch(simsProvider);
    final user = ref.watch(userProvider);

    // Calculate dynamic stats
    final int sentToday = stats.sentToday;
    final int perSimLimit = settings.dailySmsLimit;
    final int activeSimCount = settings.simPriority.length;

    String remainingText = '∞';
    if (perSimLimit != -1) {
      final int totalLimit =
          activeSimCount > 0 ? activeSimCount * perSimLimit : perSimLimit;
      final int remaining = (totalLimit - sentToday).clamp(0, totalLimit);
      remainingText = remaining.toString();
    }

    // Find active SIM carrier name
    String activeGateway = 'No active SIM';
    simsAsync.whenData((sims) {
      if (settings.activeSimId != null) {
        final activeSim =
            sims.where((s) => s.id == settings.activeSimId).firstOrNull;
        if (activeSim != null) {
          activeGateway = '${activeSim.carrierName} (${activeSim.number})';
        }
      } else if (sims.isNotEmpty) {
        activeGateway = '${sims.first.carrierName} (${sims.first.number})';
      }
    });

    final initials = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName
            .trim()
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0].toUpperCase())
            .take(2)
            .join()
        : 'U';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitBottomSheet();
        if (shouldPop && context.mounted) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SMS Mitra',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuotaWarning(sentToday, perSimLimit),
                const SizedBox(height: 16),
                _buildSectionHeader('Overview'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Sent Today',
                        sentToday.toString(),
                        Icons.send_rounded,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Remaining',
                        remainingText,
                        Icons.hourglass_bottom_rounded,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  'Active Gateway',
                  activeGateway,
                  Icons.sim_card_rounded,
                  Colors.blue,
                  isFullWidth: true,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Quick Send SMS'),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => TemplatesSheet.show(
                            context,
                            onSelect: (template) {
                              setState(() {
                                _messageController.text =
                                    template.templateMessage;
                              });
                            },
                          ),
                          icon: const Icon(Icons.bookmark_outline_rounded,
                              size: 16, color: Colors.teal),
                          label: const Text(
                            'Template',
                            style: TextStyle(
                              color: Colors.teal,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuickSendForm(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaWarning(int sent, int limit) {
    if (limit == -1 || sent < limit) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Quota Reached!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  'Your gateway will not process new SMS until tomorrow.',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return StatCard(
      label: label,
      value: value,
      icon: icon,
      color: color,
      isFullWidth: isFullWidth,
      progress: (label == 'Remaining' && value != '∞')
          ? _calculateProgress(value)
          : null,
    );
  }

  double _calculateProgress(String remainingText) {
    try {
      final settings = ref.read(settingsProvider);
      final stats = ref.read(smsStatsProvider);
      final int sentToday = stats.sentToday;
      final int perSimLimit = settings.dailySmsLimit;
      final int activeSimCount = settings.simPriority.length;
      final int totalLimit = activeSimCount * perSimLimit;

      if (totalLimit <= 0) return 0.0;
      return (sentToday / totalLimit).clamp(0.0, 1.0);
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildQuickSendForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              label: 'Receiver Number',
              hint: 'Enter 10-digit mobile number',
              icon: Icons.phone_android,
              controller: _phoneController,
              focusNode: _phoneFocus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: ValidationHelper.validatePhone,
              onFieldSubmitted: (_) => _messageFocus.requestFocus(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.contacts_rounded,
                    color: Colors.blue, size: 20),
                tooltip: 'Select from Contacts',
                onPressed: () async {
                  final contact = await ContactPickerSheet.showSingle(context);
                  if (contact != null && mounted) {
                    final raw = contact.phone.replaceAll(RegExp(r'[^0-9]'), '');
                    final phone10 =
                        raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
                    setState(() {
                      _phoneController.text = phone10;
                      _selectedContactName = contact.name.trim();
                    });
                    MessageHelper.showSuccess(
                        context, 'Selected ${contact.name}');
                  }
                },
              ),
            ),

            // Contact Name Badge & Direct Insert Action
            if (_selectedContactName != null &&
                _selectedContactName!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_circle_outlined,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedContactName!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: _showEditContactNameDialog,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 14, color: Colors.blue),
                            SizedBox(width: 3),
                            Text('Edit',
                                style: TextStyle(
                                    fontSize: 11.5, color: Colors.blue)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        _insertTextIntoMessage(_selectedContactName!);
                        MessageHelper.showSuccess(context,
                            'Inserted "$_selectedContactName" into message');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, size: 13, color: Colors.white),
                            SizedBox(width: 3),
                            Text('Insert in Message',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 16, color: Colors.grey),
                      tooltip: 'Clear Contact Name',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          setState(() => _selectedContactName = null),
                    ),
                  ],
                ),
              ),
            ],

            TextFormField(
              controller: _messageController,
              focusNode: _messageFocus,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              validator: (val) =>
                  ValidationHelper.validateNotEmpty(val, 'Message'),
              decoration: InputDecoration(
                hintText: 'Type SMS message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onFieldSubmitted: (_) => _handleSend(),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Send Now',
              onPressed: _handleSend,
              isLoading: ref.watch(smsControllerProvider).isSending,
            ),
          ],
        ),
      ),
    );
  }
}
