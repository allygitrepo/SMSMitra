import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/helpers/snackbar_helper.dart';
import '../../core/routes/app_router.dart';
import '../../data/models/sim_model.dart';
import '../../data/models/settings_model.dart';
import '../../shared/widgets/gradient_button.dart';
import 'settings_provider.dart';

/// Screen to manage SIM setup, daily limits, and theme settings.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<SimModel> _availableSims = [];
  bool _isDetecting = true;
  late TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController();
    _initDetection();
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _initDetection() async {
    debugPrint('SettingsScreen: Initializing SIM detection...');
    try {
      final sims = await ref
          .read(settingsProvider.notifier)
          .detectSims()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint(
                'SettingsScreen: SIM detection timed out after 10 seconds.',
              );
              return [];
            },
          );

      debugPrint(
        'SettingsScreen: Detection completed. SIMs found: ${sims.length}',
      );
      if (mounted) {
        setState(() {
          _availableSims = sims;
          _isDetecting = false;
        });

        // Initialize controller with current limit
        final settings = ref.read(settingsProvider);
        _limitController.text = settings.dailySmsLimit.toString();

        if (sims.isEmpty) {
          debugPrint('SettingsScreen: No SIMs found, showing warning.');
          MessageHelper.showWarning(
            context,
            'No SIM cards detected or permission denied',
          );
        }
      }
    } catch (e) {
      debugPrint('SettingsScreen: Error in _initDetection: $e');
      if (mounted) {
        setState(() => _isDetecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // Sync controller if state changes externally
    if (_limitController.text != settings.dailySmsLimit.toString()) {
      _limitController.text = settings.dailySmsLimit.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup & Settings'),
        actions: [
          IconButton(
            icon: Icon(
              settings.themeMode == 'dark'
                  ? Icons.dark_mode
                  : settings.themeMode == 'light'
                  ? Icons.light_mode
                  : Icons.settings_brightness,
            ),
            onPressed: () => notifier.cycleTheme(),
            tooltip: 'Cycle Theme',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('SIM Configuration'),
            const SizedBox(height: 12),
            if (_isDetecting)
              const Center(child: CircularProgressIndicator())
            else if (_availableSims.isEmpty)
              _buildErrorCard('No SIM cards found. Please check permissions.')
            else
              ..._availableSims.map(
                (sim) => _buildSimItem(sim, settings, notifier),
              ),

            const SizedBox(height: 48),
            GradientButton(
              text: 'Save & Continue',
              onPressed: () {
                if (settings.activeSimId == null && _availableSims.isNotEmpty) {
                  MessageHelper.showWarning(
                    context,
                    'Please select a SIM card',
                  );
                  return;
                }
                context.go(AppRouter.home);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.orange,
      ),
    );
  }

  Widget _buildSimItem(
    SimModel sim,
    SettingsModel settings,
    SettingsNotifier notifier,
  ) {
    final isSelected = sim.id == settings.activeSimId;

    return Column(
      children: [
        CheckboxListTile(
          title: Text(
            sim.carrierName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sim.number),
              const Text(
                '-1 is unlimited',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          value: isSelected,
          activeColor: Colors.orange,
          onChanged: (val) {
            notifier.updateActiveSim(val == true ? sim.id : null);
          },
          secondary: Icon(
            Icons.sim_card,
            color: isSelected ? Colors.orange : Colors.grey,
          ),
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _limitController,
                    keyboardType: TextInputType.number,

                    decoration: InputDecoration(
                      labelText: 'SMS Limit',

                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      helperText: settings.dailySmsLimit == -1
                          ? 'Unlimited'
                          : null,
                    ),
                    onChanged: (val) {
                      final limit = int.tryParse(val);
                      if (limit != null && limit >= -1) {
                        notifier.updateLimit(limit);
                      } else if (limit != null && limit < -1) {
                        _limitController.text = '-1';
                        notifier.updateLimit(-1);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: settings.limitPeriod,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'day', child: Text('Per Day')),
                      DropdownMenuItem(
                        value: 'month',
                        child: Text('Per Month'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) notifier.updateLimitPeriod(val);
                    },
                  ),
                ),
              ],
            ),
          ),
        const Divider(),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
