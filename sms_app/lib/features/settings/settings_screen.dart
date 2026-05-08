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
  /// When true, the user MUST save settings before navigating away.
  final bool isFirstTime;
  const SettingsScreen({super.key, this.isFirstTime = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  List<SimModel> _availableSims = [];
  bool _isDetecting = true;
  bool _isEditing = false;
  bool _hasSaved = false; // tracks if user saved during first-time setup
  late TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController();
    _initDetection();
    
    // Initial check for editing mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      // Force edit mode on first-time setup or if no SIM configured yet
      if (widget.isFirstTime || settings.simPriority.isEmpty) {
        setState(() => _isEditing = true);
      }
    });
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
    final isFirstTime = widget.isFirstTime;
    final hasSimSelected = settings.simPriority.isNotEmpty;

    if (_limitController.text != settings.dailySmsLimit.toString()) {
      _limitController.text = settings.dailySmsLimit.toString();
    }

    return PopScope<Object?>(
      // Block back navigation during first-time setup until saved
      canPop: !isFirstTime || _hasSaved,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && isFirstTime) {
          MessageHelper.showWarning(
            context,
            'Please select a SIM and tap "Save & Continue" to proceed.',
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isFirstTime ? 'Setup Your SIM Card' : (_isEditing ? 'Edit Settings' : 'App Settings')),
          automaticallyImplyLeading: !isFirstTime, // hide back arrow during setup
          actions: [
            if (!isFirstTime)
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
              // ── First-time onboarding banner ──
              if (isFirstTime) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade700, Colors.orange.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sim_card_alert, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to SMSMitra!',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Select and save a SIM card below to start sending messages.',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('SIM Configuration'),
                  if (!_isEditing && hasSimSelected && !isFirstTime)
                    TextButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isDetecting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Detecting SIM cards…', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else if (_availableSims.isEmpty)
                _buildErrorCard('No SIM cards found. Please check permissions.')
              else
                IgnorePointer(
                  ignoring: !_isEditing,
                  child: Opacity(
                    opacity: _isEditing ? 1.0 : 0.7,
                    child: Column(
                      children: _availableSims
                          .map((sim) => _buildSimItem(sim, settings, notifier))
                          .toList(),
                    ),
                  ),
                ),
              
              if (settings.simPriority.length > 1) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('SIM Priority (Drag to reorder)'),
                const SizedBox(height: 12),
                IgnorePointer(
                  ignoring: !_isEditing,
                  child: Opacity(
                    opacity: _isEditing ? 1.0 : 0.7,
                    child: _buildPriorityList(settings, notifier),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),

              // ── Save button (always shown during editing / first-time) ──
              if (_isEditing || isFirstTime) ...[
                if (isFirstTime && !hasSimSelected)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Select at least one SIM card above to continue.',
                            style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                GradientButton(
                  text: isFirstTime ? 'Save & Continue' : 'Update Settings',
                  onPressed: _isDetecting
                      ? null
                      : () async {
                          if (!hasSimSelected && _availableSims.isNotEmpty) {
                            MessageHelper.showWarning(
                              context,
                              'Please select at least one SIM card to continue.',
                            );
                            return;
                          }
                          await notifier.syncWithServer();
                          setState(() {
                            _isEditing = false;
                            _hasSaved = true;
                          });
                          if (!context.mounted) return;
                          MessageHelper.showSuccess(
                            context,
                            isFirstTime
                                ? 'Setup complete! Welcome to SMSMitra 🎉'
                                : 'Settings updated successfully!',
                          );
                          if (isFirstTime) {
                            context.go(AppRouter.home);
                          }
                        },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
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

  Widget _buildSimItem(SimModel sim, SettingsModel settings, SettingsNotifier notifier) {
    final priorityIndex = settings.simPriority.indexOf(sim.id);
    final isSelected = priorityIndex != -1;
    
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
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Priority #${priorityIndex + 1}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          value: isSelected,
          activeColor: Colors.orange,
          onChanged: (val) {
            notifier.toggleSim(sim.id, val == true);
            MessageHelper.showSuccess(context, val == true ? '${sim.carrierName} Enabled' : '${sim.carrierName} Disabled');
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
                        // Debounce or only show on significant change? 
                        // For now just show success
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
                      if (val != null) {
                        notifier.updateLimitPeriod(val);
                        MessageHelper.showSuccess(context, 'Limit period updated to $val');
                      }
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

  Widget _buildPriorityList(SettingsModel settings, SettingsNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex -= 1;
          final items = List<String>.from(settings.simPriority);
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);
          notifier.updatePriority(items);
          MessageHelper.showSuccess(context, 'SIM priority updated');
        },
        children: settings.simPriority
            .where((simId) => _availableSims.any((s) => s.id == simId))
            .map((simId) {
          final sim = _availableSims.firstWhere((s) => s.id == simId);
          return ListTile(
            key: ValueKey(simId),
            leading: const Icon(Icons.drag_handle, color: Colors.grey),
            title: Text(sim.carrierName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(sim.number),
            trailing: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.orange,
              child: Text(
                '${settings.simPriority.indexOf(simId) + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          );
        }).toList(),
      ),
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
