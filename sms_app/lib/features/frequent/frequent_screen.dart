import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/helpers/snackbar_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/frequent_sms_model.dart';
import '../../data/services/socket_service.dart';
import '../../shared/widgets/confirm_bottom_sheet.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/stat_card.dart';
import '../home/stats_provider.dart';
import '../schedules/schedules_screen.dart';
import 'frequent_provider.dart';
import 'widgets/frequent_sms_sheet.dart';

class FrequentScreen extends ConsumerStatefulWidget {
  const FrequentScreen({super.key});

  @override
  ConsumerState<FrequentScreen> createState() => _FrequentScreenState();
}

class _FrequentScreenState extends ConsumerState<FrequentScreen> with WidgetsBindingObserver {
  StreamSubscription<void>? _socketSubscription;
  final Set<int> _destroyingRuleIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(frequentProvider.notifier).init();
    });

    _socketSubscription = SocketService().statsUpdateStream.listen((_) {
      if (mounted) {
        ref.read(frequentProvider.notifier).fetchRules(silent: true);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(frequentProvider.notifier).fetchRules(silent: true);
    }
  }

  Future<void> _handleDeleteRule(FrequentSmsModel rule) async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      icon: Icons.delete_forever_rounded,
      iconColor: Colors.red,
      title: 'Delete Recurring Rule?',
      message: 'This periodic SMS to ${rule.receiverNumber} will be permanently stopped.',
      confirmLabel: 'Delete Rule',
      confirmColor: Colors.red,
    );

    if (confirmed && mounted && rule.id != null) {
      final ruleId = rule.id!;
      setState(() {
        _destroyingRuleIds.add(ruleId);
      });

      // Play realistic 12-shard glass shatter explosion animation
      await Future<void>.delayed(const Duration(milliseconds: 980));

      if (mounted) {
        final success = await ref.read(frequentProvider.notifier).deleteRule(ruleId);
        if (mounted) {
          setState(() {
            _destroyingRuleIds.remove(ruleId);
          });
          if (success) {
            MessageHelper.showSuccess(context, 'Recurring rule deleted');
          } else {
            MessageHelper.showError(context, 'Failed to delete rule');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final frequentState = ref.watch(frequentProvider);
    final counts = frequentState.counts;

    return RefreshIndicator(
      onRefresh: () => ref.read(frequentProvider.notifier).fetchRules(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Top Summary Stat Cards (Compact & Low-Height)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Active Rules',
                      value: '${counts['active'] ?? 0}',
                      icon: Icons.play_circle_fill_rounded,
                      color: Colors.green,
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: StatCard(
                      label: 'Paused',
                      value: '${counts['paused'] ?? 0}',
                      icon: Icons.pause_circle_filled_rounded,
                      color: Colors.amber.shade700,
                      isCompact: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: StatCard(
                      label: 'Total Sent',
                      value: '${counts['totalDispatched'] ?? 0}',
                      icon: Icons.send_rounded,
                      color: Colors.blue,
                      isCompact: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', frequentState.filterStatus),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterChip('Active', 'active', frequentState.filterStatus),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterChip('Paused', 'paused', frequentState.filterStatus),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterChip('Daily', 'daily', frequentState.filterStatus),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterChip('Weekly', 'weekly', frequentState.filterStatus),
                  const SizedBox(width: AppSpacing.xs),
                  _buildFilterChip('Monthly', 'monthly', frequentState.filterStatus),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

          // List of Recurring Rules with space-making entry & glass shatter exit
          if (frequentState.isLoading && frequentState.rules.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (frequentState.rules.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon: Icons.repeat_rounded,
                title: 'No Recurring Rules',
                description: frequentState.filterStatus == 'all'
                    ? 'Automate SMS dispatching frequently (Daily, Alternate Days, Weekly, Monthly).'
                    : 'No recurring rules match the selected filter.',
                actionLabel: 'Create Recurring SMS',
                onAction: () => FrequentSmsSheet.show(context),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final rule = frequentState.rules[index];
                    final isDestroying = rule.id != null && _destroyingRuleIds.contains(rule.id);

                    return AnimatedTimelineItem(
                      key: ValueKey('frequent_${rule.id ?? index}'),
                      isDestroying: isDestroying,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildFrequentCard(context, rule, theme),
                      ),
                    );
                  },
                  childCount: frequentState.rules.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl * 2)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String activeValue) {
    final isSelected = activeValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.orange.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.orange : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => ref.read(frequentProvider.notifier).setFilter(value),
    );
  }

  Widget _buildFrequentCard(
    BuildContext context,
    FrequentSmsModel rule,
    ThemeData theme,
  ) {
    final simsAsync = ref.watch(simsProvider);
    String simLabel = rule.simId != null ? 'SIM ${rule.simId}' : 'Auto Priority SIM';

    simsAsync.whenData((sims) {
      if (rule.simId != null) {
        final match = sims.where((s) => s.id == rule.simId);
        if (match.isNotEmpty) {
          simLabel = match.first.carrierName;
        }
      }
    });

    final isActive = rule.isActive;
    final accentColor = isActive ? rule.frequencyColor : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isActive ? accentColor.withValues(alpha: 0.3) : theme.dividerColor.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Accent Strip
          Container(
            width: 4,
            height: 48,
            margin: const EdgeInsets.only(top: 10, left: 3),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Content Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      // Top Row: Recurrence Badge, Next Run / Paused, and Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(rule.frequencyIcon, size: 12, color: accentColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        rule.formattedFrequency,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (isActive)
                                  FrequentNextCountdownBadge(nextRunAt: rule.nextRunAt)
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Paused', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          ),

                          // Active/Paused Toggle Switch
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: isActive,
                              activeThumbColor: AppColors.orange,
                              activeTrackColor: AppColors.orange.withValues(alpha: 0.4),
                              onChanged: (_) {
                                if (rule.id != null) {
                                  ref.read(frequentProvider.notifier).toggleStatus(rule.id!);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Title (if provided) & Recipient
                      if (rule.title != null && rule.title!.isNotEmpty) ...[
                        Text(
                          rule.title!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                      ],

                      Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.orange),
                          const SizedBox(width: 4),
                          Text(
                            rule.receiverNumber,
                            style: TextStyle(
                              fontWeight: rule.title != null ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Message Template Preview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          rule.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Bottom Info (SIM & Total Dispatches) + Edit/Delete Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('SIM: $simLabel', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Sent ${rule.totalDispatchedCount}x',
                                  style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // Edit Button
                              InkWell(
                                onTap: () => FrequentSmsSheet.show(context, ruleToEdit: rule),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 14, color: AppColors.orange),
                                      SizedBox(width: 3),
                                      Text('Edit', style: TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Delete Button
                              InkWell(
                                onTap: () => _handleDeleteRule(rule),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red),
                                      SizedBox(width: 3),
                                      Text('Delete', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

/// Live ticking countdown for next recurring execution
class FrequentNextCountdownBadge extends StatefulWidget {
  final DateTime nextRunAt;

  const FrequentNextCountdownBadge({super.key, required this.nextRunAt});

  @override
  State<FrequentNextCountdownBadge> createState() => _FrequentNextCountdownBadgeState();
}

class _FrequentNextCountdownBadgeState extends State<FrequentNextCountdownBadge> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatCountdown() {
    final now = DateTime.now();
    final difference = widget.nextRunAt.difference(now);

    if (difference.isNegative) {
      return 'Due now';
    }

    final totalSeconds = difference.inSeconds;
    if (totalSeconds < 60) {
      return 'In ${totalSeconds}s';
    } else if (totalSeconds < 3600) {
      final mins = difference.inMinutes;
      final secs = totalSeconds % 60;
      return 'In ${mins}m ${secs.toString().padLeft(2, '0')}s';
    } else if (difference.inHours < 24 && widget.nextRunAt.day == now.day) {
      return 'Today @ ${DateFormat('hh:mm a').format(widget.nextRunAt)}';
    } else if (difference.inHours < 48 && widget.nextRunAt.day == now.day + 1) {
      return 'Tomorrow @ ${DateFormat('hh:mm a').format(widget.nextRunAt)}';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(widget.nextRunAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
        const SizedBox(width: 3),
        Text(
          _formatCountdown(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
      ],
    );
  }
}
