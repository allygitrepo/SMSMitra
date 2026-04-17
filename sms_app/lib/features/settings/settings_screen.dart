import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/helpers/snackbar_helper.dart';
import '../../core/routes/app_router.dart';
import '../../data/models/sim_model.dart';
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

  @override
  void initState() {
    super.initState();
    _initDetection();
  }

  Future<void> _initDetection() async {
    debugPrint('SettingsScreen: Initializing SIM detection...');
    try {
      // Add a timeout to prevent infinite loader if plugin hangs
      final sims = await ref
          .read(settingsProvider.notifier)
          .detectSims()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint('SettingsScreen: SIM detection timed out after 10 seconds.');
        return [];
      });

      debugPrint('SettingsScreen: Detection completed. SIMs found: ${sims.length}');
      if (mounted) {
        setState(() {
          _availableSims = sims;
          _isDetecting = false;
        });
        if (sims.isEmpty) {
          debugPrint('SettingsScreen: No SIMs found, showing warning.');
          MessageHelper.showWarning(context, 'No SIM cards detected or permission denied');
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
              ..._availableSims.map((sim) => _buildSimCard(sim, settings.activeSimId, notifier)),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Daily SMS Limit'),
            const SizedBox(height: 12),
            _buildLimitSelector(settings.dailySmsLimit, notifier),
            
            const SizedBox(height: 48),
            GradientButton(
              text: 'Save & Continue',
              onPressed: () {
                if (settings.activeSimId == null && _availableSims.isNotEmpty) {
                  MessageHelper.showWarning(context, 'Please select a SIM card');
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

  Widget _buildSimCard(SimModel sim, String? activeId, SettingsNotifier notifier) {
    final isSelected = sim.id == activeId;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.orange : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          child: Icon(Icons.sim_card, color: isSelected ? Colors.orange : Colors.grey),
        ),
        title: Text(sim.carrierName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Slot ${sim.slotIndex + 1} • ${sim.number}'),
        trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.orange) : null,
        onTap: () => notifier.updateActiveSim(sim.id),
      ),
    );
  }

  Widget _buildLimitSelector(int currentLimit, SettingsNotifier notifier) {
    final limits = [100, 500, 1000, -1];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: limits.map((limit) {
        final isSelected = currentLimit == limit;
        final label = limit == -1 ? 'Unlimited' : '$limit/day';
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => notifier.updateLimit(limit),
          selectedColor: Colors.orange.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected ? Colors.orange : null,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
      }).toList(),
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
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
