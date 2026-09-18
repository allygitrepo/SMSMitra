import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_router.dart';
import '../../core/helpers/validation_helper.dart';
import '../../core/helpers/snackbar_helper.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/gradient_button.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/confirm_bottom_sheet.dart';
import '../settings/settings_provider.dart';
import '../schedules/widgets/schedule_sms_sheet.dart';
import '../frequent/widgets/frequent_sms_sheet.dart';
import '../bulk_sms/widgets/templates_sheet.dart';
import 'stats_provider.dart';
import 'sms_controller.dart';
import '../../data/services/socket_service.dart';

/// The main operational screen of the app where users send SMS.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _messageFocus = FocusNode();
  bool _isSyncing = false;
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
    setState(() => _isSyncing = true);
    try {
      await ref.read(smsStatsProvider.notifier).fetchStats();
      // ignore: unused_result
      await ref.refresh(simsProvider.future);
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
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

  Future<void> _handleSend() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(smsControllerProvider.notifier).sendQuickSms(
        phone: _phoneController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (!mounted) return;

      final smsState = ref.read(smsControllerProvider);
      if (success) {
        MessageHelper.showSuccess(context, smsState.successMessage ?? 'SMS dispatched successfully!');
        _messageController.clear();
      } else {
        MessageHelper.showError(context, smsState.errorMessage ?? 'Failed to send SMS');
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

    // Calculate dynamic stats
    final int sentToday = stats.sentToday;
    final int perSimLimit = settings.dailySmsLimit;
    final int activeSimCount = settings.simPriority.length;

    String remainingText = '∞';
    if (perSimLimit != -1) {
      final int totalLimit = activeSimCount > 0 ? activeSimCount * perSimLimit : perSimLimit;
      final int remaining = (totalLimit - sentToday).clamp(0, totalLimit);
      remainingText = remaining.toString();
    }

    // Find active SIM carrier name
    String activeGateway = 'No active SIM';
    simsAsync.whenData((sims) {
      if (settings.activeSimId != null) {
        final activeSim = sims
            .where((s) => s.id == settings.activeSimId)
            .firstOrNull;
        if (activeSim != null) {
          activeGateway = '${activeSim.carrierName} (${activeSim.number})';
        }
      } else if (sims.isNotEmpty) {
        activeGateway = '${sims.first.carrierName} (${sims.first.number})';
      }
    });

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
          title: const Text('SMS Mitra', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: false,
          actions: [
            IconButton(
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Sync Stats',
              onPressed: _isSyncing ? null : _refreshData,
            ),
            const SizedBox(width: 8),
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

                // ── Bulk SMS & Templates Hub ────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.campaign_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Bulk SMS & Templates',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => TemplatesSheet.show(context),
                            icon: const Icon(Icons.bookmark_outline_rounded, size: 16),
                            label: const Text('Templates', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Import CSV contacts, map custom column placeholders, and dispatch multi-recipient SMS campaigns.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => context.push(AppRouter.bulkSms),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.send_and_archive_rounded, size: 18),
                        label: const Text(
                          'Launch Bulk SMS Campaign',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader('Quick Send SMS'),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => ScheduleSmsSheet.show(context),
                          icon: const Icon(Icons.schedule, size: 16, color: Colors.orange),
                          label: const Text(
                            'Schedule',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => FrequentSmsSheet.show(context),
                          icon: const Icon(Icons.repeat_rounded, size: 16, color: Colors.purple),
                          label: const Text(
                            'Recurring',
                            style: TextStyle(
                              color: Colors.purple,
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
      progress: (label == 'Remaining' && value != '∞') ? _calculateProgress(value) : null,
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
            ),
            const SizedBox(height: 16),
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
