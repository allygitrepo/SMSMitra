import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/helpers/snackbar_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/scheduled_sms_model.dart';
import '../../data/services/socket_service.dart';
import '../../shared/widgets/confirm_bottom_sheet.dart';
import '../../shared/widgets/empty_state_widget.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../home/stats_provider.dart';
import 'schedules_provider.dart';
import 'widgets/schedule_sms_sheet.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> with WidgetsBindingObserver {
  StreamSubscription<void>? _socketSubscription;
  final Set<int> _destroyingScheduleIds = {};
  final Set<int> _dispatchedScheduleIds = {};
  final Set<int> _handledDispatchIds = {};
  final Map<int, String> _lastKnownStatuses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      ref.read(schedulesProvider.notifier).init();
    });

    _socketSubscription = SocketService().statsUpdateStream.listen((_) {
      if (mounted) {
        ref.read(schedulesProvider.notifier).fetchSchedules(silent: true);
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
      ref.read(schedulesProvider.notifier).fetchSchedules(silent: true);
    }
  }

  Future<void> _handleCancelSchedule(ScheduledSmsModel schedule) async {
    final confirmed = await ConfirmBottomSheet.show(
      context,
      icon: Icons.cancel_schedule_send_rounded,
      iconColor: Colors.red,
      title: 'Cancel Scheduled SMS?',
      message: 'This message will not be sent to ${schedule.receiverNumber}.',
      confirmLabel: 'Cancel Schedule',
      confirmColor: Colors.red,
    );

    if (confirmed && mounted && schedule.id != null) {
      final scheduleId = schedule.id!;
      setState(() {
        _destroyingScheduleIds.add(scheduleId);
      });

      // Play realistic glass shatter explosion animation before API dispatch
      await Future<void>.delayed(const Duration(milliseconds: 980));

      if (mounted) {
        final success = await ref.read(schedulesProvider.notifier).cancelSchedule(scheduleId);
        if (mounted) {
          setState(() {
            _destroyingScheduleIds.remove(scheduleId);
          });
          if (success) {
            MessageHelper.showSuccess(context, 'Schedule cancelled successfully');
          } else {
            MessageHelper.showError(context, 'Failed to cancel schedule');
          }
        }
      }
    }
  }

  Future<void> _triggerDispatchAnimation(int scheduleId) async {
    if (_dispatchedScheduleIds.contains(scheduleId) ||
        _destroyingScheduleIds.contains(scheduleId) ||
        _handledDispatchIds.contains(scheduleId)) {
      return;
    }

    _handledDispatchIds.add(scheduleId);
    if (mounted) {
      setState(() {
        _dispatchedScheduleIds.add(scheduleId);
      });
    }

    // Allow realistic glass shatter explosion animation to play completely
    await Future<void>.delayed(const Duration(milliseconds: 980));

    if (mounted) {
      // Optimistically mark dispatched so card never reappears on Upcoming tab
      ref.read(schedulesProvider.notifier).markScheduleDispatched(scheduleId);
      // Sync schedules silently with server
      await ref.read(schedulesProvider.notifier).fetchSchedules(silent: true);
      if (mounted) {
        setState(() {
          _dispatchedScheduleIds.remove(scheduleId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedulesState = ref.watch(schedulesProvider);
    final counts = schedulesState.counts;

    // Detect newly dispatched/completed schedules in real-time
    for (final s in schedulesState.schedules) {
      if (s.id != null) {
        final prevStatus = _lastKnownStatuses[s.id!];
        if (prevStatus == 'scheduled' && s.status == 'completed' && !_handledDispatchIds.contains(s.id!)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerDispatchAnimation(s.id!);
          });
        }
        _lastKnownStatuses[s.id!] = s.status;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheduled SMS', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: schedulesState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: schedulesState.isLoading
                ? null
                : () => ref.read(schedulesProvider.notifier).fetchSchedules(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScheduleSmsSheet.show(context),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Schedule SMS'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(schedulesProvider.notifier).fetchSchedules(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Top Summary Cards (Compact & Low-Height)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Upcoming',
                        value: '${counts['scheduled'] ?? 0}',
                        icon: Icons.alarm_on_rounded,
                        color: Colors.orange,
                        isCompact: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: StatCard(
                        label: 'Completed',
                        value: '${counts['completed'] ?? 0}',
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        isCompact: true,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: StatCard(
                        label: 'Cancelled',
                        value: '${counts['cancelled'] ?? 0}',
                        icon: Icons.cancel_outlined,
                        color: Colors.grey,
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
                    _buildFilterChip('All', 'all', schedulesState.filterStatus),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('Upcoming', 'scheduled', schedulesState.filterStatus),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('Completed', 'completed', schedulesState.filterStatus),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('Cancelled', 'cancelled', schedulesState.filterStatus),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),

            // List of Schedules / Google Calendar Timeline
            if (schedulesState.isLoading && schedulesState.schedules.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (schedulesState.schedules.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  icon: Icons.alarm_off_rounded,
                  title: 'No Scheduled Messages',
                  description: schedulesState.filterStatus == 'all'
                      ? 'You have not scheduled any outbound messages yet.'
                      : 'No scheduled messages match the selected filter.',
                  actionLabel: 'Schedule Now',
                  onAction: () => ScheduleSmsSheet.show(context),
                ),
              )
            else
              _buildTimelineSlivers(context, schedulesState.schedules, theme),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
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
      onSelected: (_) => ref.read(schedulesProvider.notifier).setFilter(value),
    );
  }

  Widget _buildTimelineSlivers(
    BuildContext context,
    List<ScheduledSmsModel> schedules,
    ThemeData theme,
  ) {
    // Group schedules by calendar date
    final Map<DateTime, List<ScheduledSmsModel>> grouped = {};
    for (final schedule in schedules) {
      final dateKey = DateTime(
        schedule.scheduledAt.year,
        schedule.scheduledAt.month,
        schedule.scheduledAt.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(schedule);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final date = sortedDates[index];
            final items = grouped[date]!;
            return _buildDaySection(context, date, items, theme);
          },
          childCount: sortedDates.length,
        ),
      ),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    DateTime date,
    List<ScheduledSmsModel> items,
    ThemeData theme,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    String dayLabel;
    bool isCurrentDay = false;

    if (date.isAtSameMomentAs(today)) {
      dayLabel = 'Today • ${DateFormat('EEEE, d MMM').format(date)}';
      isCurrentDay = true;
    } else if (date.isAtSameMomentAs(tomorrow)) {
      dayLabel = 'Tomorrow • ${DateFormat('EEEE, d MMM').format(date)}';
    } else {
      dayLabel = DateFormat('EEEE, d MMM yyyy').format(date);
    }

    return Column(
      key: ValueKey('day_section_${date.toIso8601String()}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Google Calendar Day Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isCurrentDay
                      ? AppColors.orange
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isCurrentDay
                        ? AppColors.orange
                        : theme.dividerColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(date).toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isCurrentDay ? Colors.white : Colors.grey,
                      ),
                    ),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCurrentDay ? Colors.white : theme.textTheme.bodyMedium?.color,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentDay ? AppColors.orange : theme.textTheme.bodyMedium?.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: Text(
                    '${items.length} ${items.length == 1 ? 'SMS' : 'SMS'}',
                    key: ValueKey('count_${items.length}'),
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Animated Timeline Items for this Day
        ...List.generate(items.length, (i) {
          final isLast = i == items.length - 1;
          final item = items[i];
          final isDestroying = item.id != null && _destroyingScheduleIds.contains(item.id);
          final isDispatched = item.id != null && _dispatchedScheduleIds.contains(item.id);

          return AnimatedTimelineItem(
            key: ValueKey(item.id ?? item.scheduledAt.toIso8601String()),
            isDestroying: isDestroying,
            isDispatched: isDispatched,
            child: _buildTimelineEventRow(context, item, isLast, theme),
          );
        }),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildTimelineEventRow(
    BuildContext context,
    ScheduledSmsModel schedule,
    bool isLast,
    ThemeData theme,
  ) {
    final isDestroying = schedule.id != null && _destroyingScheduleIds.contains(schedule.id);
    final isDispatched = schedule.id != null && _dispatchedScheduleIds.contains(schedule.id);
    final isPending = schedule.isPending && !isDestroying && !isDispatched;
    final isCompleted = schedule.isCompleted || isDispatched;

    final Color statusColor = isDestroying
        ? Colors.red
        : (isDispatched
            ? Colors.green
            : (isPending
                ? AppColors.orange
                : (isCompleted ? Colors.green : Colors.grey)));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line & Node Dot
          SizedBox(
            width: 38,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutCubic,
                  width: 2,
                  height: 12,
                  color: isDestroying
                      ? Colors.red.withValues(alpha: 0.6)
                      : (isDispatched
                          ? Colors.green.withValues(alpha: 0.6)
                          : theme.dividerColor.withValues(alpha: 0.6)),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                    boxShadow: isPending || isDestroying || isDispatched
                        ? [
                            BoxShadow(
                              color: (isDestroying
                                      ? Colors.red
                                      : (isDispatched ? Colors.green : AppColors.orange))
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
                Expanded(
                  child: isLast
                      ? const SizedBox.shrink()
                      : AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOutCubic,
                          width: 2,
                          color: isDestroying
                              ? Colors.red.withValues(alpha: 0.6)
                              : (isDispatched
                                  ? Colors.green.withValues(alpha: 0.6)
                                  : theme.dividerColor.withValues(alpha: 0.6)),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Google Calendar Style Event Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildGoogleCalendarCard(context, schedule, statusColor, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleCalendarCard(
    BuildContext context,
    ScheduledSmsModel schedule,
    Color accentColor,
    ThemeData theme,
  ) {
    final simsAsync = ref.watch(simsProvider);
    String simLabel = schedule.simId != null ? 'SIM ${schedule.simId}' : 'Auto Priority SIM';

    simsAsync.whenData((sims) {
      if (schedule.simId != null) {
        final match = sims.where((s) => s.id == schedule.simId);
        if (match.isNotEmpty) {
          simLabel = match.first.carrierName;
        }
      }
    });

    final isDestroying = schedule.id != null && _destroyingScheduleIds.contains(schedule.id);
    final isDispatched = schedule.id != null && _dispatchedScheduleIds.contains(schedule.id);
    final isPending = schedule.isPending && !isDestroying && !isDispatched;
    final effectiveAccent = isDestroying
        ? Colors.red
        : (isDispatched ? Colors.green : accentColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: isDestroying
            ? Colors.red.withValues(alpha: 0.08)
            : (isDispatched
                ? Colors.green.withValues(alpha: 0.08)
                : theme.cardColor),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDestroying
              ? Colors.red
              : (isDispatched
                  ? Colors.green
                  : (isPending
                      ? AppColors.orange.withValues(alpha: 0.25)
                      : theme.dividerColor.withValues(alpha: 0.7))),
        ),
        boxShadow: isDestroying || isDispatched
            ? [
                BoxShadow(
                  color: (isDestroying ? Colors.red : Colors.green).withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Strip (Google Calendar style)
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                width: 4,
                color: effectiveAccent,
              ),

              // Card Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Time, Countdown, StatusBadge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeInOutCubic,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: effectiveAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  DateFormat('hh:mm a').format(schedule.scheduledAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: effectiveAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                                child: isPending
                                    ? ScheduleCountdownBadge(
                                        key: const ValueKey('pending_countdown'),
                                        scheduledAt: schedule.scheduledAt,
                                        isPending: isPending,
                                        onCountdownComplete: schedule.id != null
                                            ? () => _triggerDispatchAnimation(schedule.id!)
                                            : null,
                                      )
                                    : schedule.isCompleted
                                        ? const Row(
                                            key: ValueKey('completed_label'),
                                            children: [
                                              Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                                              SizedBox(width: 4),
                                              Text(
                                                'Dispatched',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink(key: ValueKey('none')),
                              ),
                            ],
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                              child: FadeTransition(opacity: animation, child: child),
                            ),
                            child: StatusBadge(
                              key: ValueKey('status_${schedule.status}'),
                              status: schedule.status,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Recipient
                      Row(
                        children: [
                          const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.orange),
                          const SizedBox(width: 4),
                          Text(
                            schedule.receiverNumber,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Message Preview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          schedule.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      // Bottom Info & Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gateway: $simLabel',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => SizeTransition(
                              sizeFactor: animation,
                              axis: Axis.horizontal,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                            child: isPending
                                ? Row(
                                    key: const ValueKey('pending_actions'),
                                    children: [
                                      // Edit Button
                                      InkWell(
                                        onTap: () => ScheduleSmsSheet.show(
                                          context,
                                          scheduleToEdit: schedule,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 14, color: AppColors.orange),
                                              SizedBox(width: 3),
                                              Text(
                                                'Edit',
                                                style: TextStyle(
                                                  color: AppColors.orange,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Cancel Button
                                      InkWell(
                                        onTap: () => _handleCancelSchedule(schedule),
                                        borderRadius: BorderRadius.circular(6),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
                                              SizedBox(width: 3),
                                              Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(key: ValueKey('no_actions')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Model representing an individual geometric glass shard
class _GlassShard {
  final List<Offset> points;
  final double dx;
  final double dy;
  final double rotation;

  const _GlassShard({
    required this.points,
    required this.dx,
    required this.dy,
    required this.rotation,
  });

  Path createPath(Size size) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx * size.width, points[0].dy * size.height);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx * size.width, points[i].dy * size.height);
    }
    path.close();
    return path;
  }
}

class _ShardClipper extends CustomClipper<Path> {
  final Path path;
  _ShardClipper(this.path);

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(covariant _ShardClipper oldClipper) => path != oldClipper.path;
}

const List<_GlassShard> _kGlassShards = [
  // Top Left quadrant shards
  _GlassShard(
    points: [Offset(0.0, 0.0), Offset(0.35, 0.0), Offset(0.25, 0.40)],
    dx: -90,
    dy: -80,
    rotation: -0.7,
  ),
  _GlassShard(
    points: [Offset(0.35, 0.0), Offset(0.70, 0.0), Offset(0.50, 0.45), Offset(0.25, 0.40)],
    dx: -15,
    dy: -95,
    rotation: 0.5,
  ),
  // Top Right quadrant shards
  _GlassShard(
    points: [Offset(0.70, 0.0), Offset(1.0, 0.0), Offset(1.0, 0.35), Offset(0.75, 0.30)],
    dx: 85,
    dy: -85,
    rotation: 0.8,
  ),
  _GlassShard(
    points: [Offset(0.70, 0.0), Offset(0.75, 0.30), Offset(0.50, 0.45)],
    dx: 50,
    dy: -65,
    rotation: -0.6,
  ),
  // Right side shards
  _GlassShard(
    points: [Offset(1.0, 0.35), Offset(1.0, 0.70), Offset(0.75, 0.55), Offset(0.75, 0.30)],
    dx: 110,
    dy: 5,
    rotation: 0.9,
  ),
  _GlassShard(
    points: [Offset(1.0, 0.70), Offset(1.0, 1.0), Offset(0.70, 1.0), Offset(0.75, 0.55)],
    dx: 95,
    dy: 90,
    rotation: -0.8,
  ),
  // Bottom side shards
  _GlassShard(
    points: [Offset(0.70, 1.0), Offset(0.40, 1.0), Offset(0.50, 0.60), Offset(0.75, 0.55)],
    dx: 30,
    dy: 110,
    rotation: 0.6,
  ),
  _GlassShard(
    points: [Offset(0.40, 1.0), Offset(0.0, 1.0), Offset(0.20, 0.65), Offset(0.50, 0.60)],
    dx: -60,
    dy: 115,
    rotation: -0.7,
  ),
  // Left side shards
  _GlassShard(
    points: [Offset(0.0, 1.0), Offset(0.0, 0.55), Offset(0.20, 0.65)],
    dx: -110,
    dy: 60,
    rotation: 0.8,
  ),
  _GlassShard(
    points: [Offset(0.0, 0.55), Offset(0.0, 0.0), Offset(0.25, 0.40), Offset(0.20, 0.65)],
    dx: -105,
    dy: -30,
    rotation: -0.9,
  ),
  // Center impact core shards
  _GlassShard(
    points: [Offset(0.25, 0.40), Offset(0.50, 0.45), Offset(0.50, 0.60), Offset(0.20, 0.65)],
    dx: -25,
    dy: 15,
    rotation: -0.5,
  ),
  _GlassShard(
    points: [Offset(0.50, 0.45), Offset(0.75, 0.30), Offset(0.75, 0.55), Offset(0.50, 0.60)],
    dx: 40,
    dy: 20,
    rotation: 0.6,
  ),
];

class _CrackLinesPainter extends CustomPainter {
  final double opacity;
  final Color accentColor;

  _CrackLinesPainter({
    required this.opacity,
    this.accentColor = Colors.redAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintWhite = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.95)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintAccent = Paint()
      ..color = accentColor.withValues(alpha: opacity * 0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final shard in _kGlassShards) {
      final path = shard.createPath(size);
      canvas.drawPath(path, paintWhite);
      canvas.drawPath(path, paintAccent);
    }
  }

  @override
  bool shouldRepaint(covariant _CrackLinesPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.accentColor != accentColor;
}

/// A smooth entry & realistic glass shatter destruction container for timeline cards.
/// - On Entry: Opens space between adjacent cards and pops in.
/// - On Cancel / Dispatch: Shatters into 12 polygon glass shards with fracture lines
///   (red for cancel, emerald green for dispatch) and outward dispersion physics,
///   then collapses space so surrounding cards close the gap.
class AnimatedTimelineItem extends StatefulWidget {
  final Widget child;
  final bool isDestroying;
  final bool isDispatched;

  const AnimatedTimelineItem({
    super.key,
    required this.child,
    this.isDestroying = false,
    this.isDispatched = false,
  });

  @override
  State<AnimatedTimelineItem> createState() => _AnimatedTimelineItemState();
}

class _AnimatedTimelineItemState extends State<AnimatedTimelineItem>
    with TickerProviderStateMixin {
  late final AnimationController _entryController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  late final Animation<double> _entrySize = CurvedAnimation(
    parent: _entryController,
    curve: const Interval(0.0, 0.70, curve: Curves.fastOutSlowIn),
  );

  late final Animation<double> _entryScale = Tween<double>(begin: 0.88, end: 1.0).animate(
    CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutBack),
    ),
  );

  late final Animation<double> _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.15, 0.80, curve: Curves.easeOut),
    ),
  );

  late final Animation<Offset> _entrySlide = Tween<Offset>(
    begin: const Offset(0, 0.05),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.20, 1.0, curve: Curves.easeOutCubic),
    ),
  );

  late final AnimationController _destroyController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  late final Animation<double> _destroyHeight = Tween<double>(begin: 1.0, end: 0.0).animate(
    CurvedAnimation(
      parent: _destroyController,
      curve: const Interval(0.45, 1.0, curve: Curves.easeInOutCubic),
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isDestroying || widget.isDispatched) {
      _destroyController.forward();
    } else {
      _entryController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedTimelineItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = oldWidget.isDestroying || oldWidget.isDispatched;
    final isNowActive = widget.isDestroying || widget.isDispatched;
    if (isNowActive && !wasActive) {
      _destroyController.forward();
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _destroyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDestroying || widget.isDispatched) {
      final shatterColor = widget.isDispatched ? Colors.greenAccent : Colors.redAccent;

      return AnimatedBuilder(
        animation: _destroyController,
        builder: (context, _) {
          final progress = _destroyController.value;
          final crackOpacity = (1.0 - progress * 1.6).clamp(0.0, 1.0);

          return SizeTransition(
            sizeFactor: _destroyHeight,
            axis: Axis.vertical,
            alignment: Alignment.topCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight.isFinite && constraints.maxHeight > 0
                    ? constraints.maxHeight
                    : 140.0;
                final size = Size(width, height);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ..._kGlassShards.map((shard) {
                      final path = shard.createPath(size);
                      final tx = shard.dx * progress * 1.15;
                      final ty = shard.dy * progress * 1.05 + (110 * progress * progress);
                      final rot = shard.rotation * progress * 1.25;
                      final shardOpacity = (1.0 - progress * 1.15).clamp(0.0, 1.0);
                      final shardScale = (1.0 - progress * 0.25).clamp(0.0, 1.0);

                      return Transform.translate(
                        offset: Offset(tx, ty),
                        child: Transform.rotate(
                          angle: rot,
                          child: Transform.scale(
                            scale: shardScale,
                            child: Opacity(
                              opacity: shardOpacity,
                              child: ClipPath(
                                clipper: _ShardClipper(path),
                                child: widget.child,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (crackOpacity > 0.0)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CrackLinesPainter(
                            opacity: crackOpacity,
                            accentColor: shatterColor,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          );
        },
      );
    }

    return SizeTransition(
      sizeFactor: _entrySize,
      axis: Axis.vertical,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _entryFade,
        child: ScaleTransition(
          scale: _entryScale,
          child: SlideTransition(
            position: _entrySlide,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// An isolated, self-updating live countdown badge that ticks every second (59s -> 58s -> 57s)
class ScheduleCountdownBadge extends StatefulWidget {
  final DateTime scheduledAt;
  final bool isPending;
  final VoidCallback? onCountdownComplete;

  const ScheduleCountdownBadge({
    super.key,
    required this.scheduledAt,
    required this.isPending,
    this.onCountdownComplete,
  });

  @override
  State<ScheduleCountdownBadge> createState() => _ScheduleCountdownBadgeState();
}

class _ScheduleCountdownBadgeState extends State<ScheduleCountdownBadge> {
  Timer? _ticker;
  bool _hasTriggered = false;

  @override
  void initState() {
    super.initState();
    if (widget.isPending) {
      _startTicker();
    }
  }

  @override
  void didUpdateWidget(covariant ScheduleCountdownBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPending != oldWidget.isPending) {
      if (widget.isPending) {
        _startTicker();
      } else {
        _ticker?.cancel();
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        if (widget.isPending && !_hasTriggered && DateTime.now().isAfter(widget.scheduledAt)) {
          _hasTriggered = true;
          widget.onCountdownComplete?.call();
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final now = DateTime.now();
    final difference = widget.scheduledAt.difference(now);

    if (difference.isNegative) {
      if (widget.isPending && difference.inSeconds.abs() < 60) {
        return 'Dispatching now...';
      }
      return DateFormat('dd MMM yyyy, hh:mm a').format(widget.scheduledAt);
    }

    final totalSeconds = difference.inSeconds;
    if (totalSeconds < 60) {
      return totalSeconds <= 0 ? 'Dispatching now...' : 'In ${totalSeconds}s';
    } else if (totalSeconds < 3600) {
      final mins = difference.inMinutes;
      final secs = totalSeconds % 60;
      return 'In ${mins}m ${secs.toString().padLeft(2, '0')}s';
    } else if (difference.inHours < 24 && widget.scheduledAt.day == now.day) {
      return 'Today at ${DateFormat('hh:mm a').format(widget.scheduledAt)}';
    } else if (difference.inHours < 48 && widget.scheduledAt.day == now.day + 1) {
      return 'Tomorrow at ${DateFormat('hh:mm a').format(widget.scheduledAt)}';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(widget.scheduledAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          _formatTime(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.isPending ? AppColors.orange : Colors.grey,
          ),
        ),
      ],
    );
  }
}
