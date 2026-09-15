import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/helpers/validation_helper.dart';
import '../../core/helpers/snackbar_helper.dart';
import '../../data/services/sms_service.dart';
import '../../data/services/sms_api_service.dart';
import 'package:sms_app/data/services/storage_service.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/gradient_button.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings/settings_provider.dart';
import 'stats_provider.dart';
import '../../data/services/socket_service.dart';

/// The main operational screen of the app where users send SMS.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  final _smsService = SmsService();
  bool _isSending = false;
  bool _isSyncing = false;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  StreamSubscription<void>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
    // Listen for real-time stats updates from server
    _fcmSubscription = FirebaseMessaging.onMessage.listen((message) {
      if (message.data['type'] == 'STATS_UPDATE') {
        debugPrint("HomeScreen: Received real-time stats update trigger");
        _refreshData();
      }
    });

    SocketService().initSocket();
    _socketSubscription = SocketService().statsUpdateStream.listen((_) {
      debugPrint("HomeScreen: Received Socket stats update trigger");
      _refreshData();
    });
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
    _fcmSubscription?.cancel();
    _socketSubscription?.cancel();
    SocketService().disconnect();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSending = true);

      try {
        final permission = await _smsService.requestPermissions();
        if (!permission) {
          if (mounted) {
            MessageHelper.showError(
              context,
              'SMS Permission denied. Please enable in settings.',
            );
          }
          return;
        }

        // Quota check
        final stats = ref.read(smsStatsProvider);
        final settings = ref.read(settingsProvider);
        final sentToday = stats['sentToday'] ?? 0;
        final dailyLimit = settings.dailySmsLimit;

        if (sentToday >= dailyLimit) {
          if (mounted) {
            MessageHelper.showError(
              context,
              'Daily SMS limit reached ($dailyLimit). Please increase limit in settings.',
            );
          }
          return;
        }

        final number = _phoneController.text.trim();
        final message = _messageController.text.trim();

        await _smsService.sendSms(number: number, message: message);

        ref.read(settingsProvider);
        final user = StorageService.getUser();
        if (user != null) {
          await SmsApiService().createManualLog(
            userId: user.id.toString(),
            phoneNumber: number,
            message: message,
            status: 'sent',
            simId: settings.activeSimId,
          );
        }

        if (mounted) {
          ref.read(smsStatsProvider.notifier).incrementSent();
          MessageHelper.showSuccess(context, 'SMS sent successfully!');
          _messageController.clear(); // Clear message after success
        }
      } catch (e) {
        // Log failure to server if user exists
        final settings = ref.read(settingsProvider);
        final user = StorageService.getUser();
        if (user != null) {
          await SmsApiService().createManualLog(
            userId: user.id.toString(),
            phoneNumber: _phoneController.text.trim(),
            message: _messageController.text.trim(),
            status: 'failed',
            simId: settings.activeSimId,
          );
        }

        if (mounted) {
          ref.read(smsStatsProvider.notifier).incrementFailed();
          MessageHelper.showError(context, e);
        }
      } finally {
        if (mounted) {
          setState(() => _isSending = false);
        }
      }
    }
  }


  Future<bool> _showExitBottomSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.exit_to_app_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Exit Application?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to close SMS Mitra?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Colors.orange)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('Exit Now'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final stats = ref.watch(smsStatsProvider);
    final simsAsync = ref.watch(simsProvider);

    // Calculate dynamic stats
    final int sentToday = stats['sentToday'] ?? 0;
    final int perSimLimit = settings.dailySmsLimit;
    final int activeSimCount = settings.simPriority.length;

    String remainingText = '∞';
    if (perSimLimit != -1) {
      final int totalLimit = activeSimCount * perSimLimit;
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
          SystemNavigator.pop();
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
                const SizedBox(height: 28),
                _buildSectionHeader('Quick Send SMS'),
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
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
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
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (label == 'Remaining' && value != '∞') ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _calculateProgress(value),
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _calculateProgress(String remainingText) {
    try {
      final settings = ref.read(settingsProvider);
      final stats = ref.read(smsStatsProvider);
      final int sentToday = stats['sentToday'] ?? 0;
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
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              label: 'Receiver Number',
              hint: '+91',
              icon: Icons.phone_android,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: ValidationHelper.validatePhone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              validator: (val) =>
                  ValidationHelper.validateNotEmpty(val, 'Message'),
              decoration: InputDecoration(
                hintText: 'Type message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Send Now',
              onPressed: _handleSend,
              isLoading: _isSending,
            ),
          ],
        ),
      ),
    );
  }
}
