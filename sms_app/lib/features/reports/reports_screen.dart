import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sms_app/features/home/stats_provider.dart';
import '../../core/utils/pdf_generator.dart';
import '../../data/models/sms_log_model.dart';
import '../../data/models/settings_model.dart';
import '../../features/reports/reports_provider.dart';
import '../../features/settings/settings_provider.dart';
import '../../data/services/socket_service.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/empty_state_widget.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with WidgetsBindingObserver {
  StreamSubscription<void>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).init();
    });

    _socketSubscription = SocketService().statsUpdateStream.listen((_) {
      if (mounted) {
        ref.read(reportsProvider.notifier).fetchReports();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(reportsProvider.notifier).fetchReports();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: state.logs.isEmpty
                ? null
                : () => PdfGenerator.generateSmsReport(
                    logs: state.logs,
                    stats: state.stats,
                    startDate: state.startDate,
                    endDate: state.endDate,
                  ),
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(reportsProvider.notifier).fetchReports(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context, state, settings),
          _buildStatCards(state.stats),
          if (state.errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(reportsProvider.notifier).fetchReports(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.logs.isEmpty
                    ? _buildEmptyState()
                    : _buildLogsTable(state.logs),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    ReportsState state,
    SettingsModel settings,
  ) {
    final theme = Theme.of(context);
    final simsAsync = ref.watch(simsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: theme.cardColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            SizedBox(
              height: 45,
              child: InkWell(
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                    initialDateRange:
                        state.startDate != null && state.endDate != null
                            ? DateTimeRange(
                                start: state.startDate!,
                                end: state.endDate!,
                              )
                            : null,
                    builder: (context, child) {
                      return Theme(
                        data: theme.copyWith(
                          colorScheme: theme.colorScheme.copyWith(
                            primary: Colors.orange,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (range != null) {
                    ref
                        .read(reportsProvider.notifier)
                        .updateDateRange(range.start, range.end);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        state.startDate == null
                            ? 'Date Range'
                            : '${DateFormat('dd MMM').format(state.startDate!)} - ${DateFormat('dd MMM').format(state.endDate!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 45,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.simId ?? 'all',
                    isDense: true,
                    dropdownColor: theme.cardColor,
                    icon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
                    items: <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'all',
                        child: Text(
                          'All SIMs',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      ...settings.simPriority.map<DropdownMenuItem<String>>((String simId) {
                        String label =
                            'SIM ${settings.simPriority.indexOf(simId) + 1}';

                        simsAsync.whenData((sims) {
                          try {
                            final sim = sims.firstWhere((s) => s.id == simId);
                            label = sim.carrierName;
                          } catch (_) {}
                        });

                        return DropdownMenuItem<String>(
                          value: simId,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      ref.read(reportsProvider.notifier).updateSimFilter(val);
                    },
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(Map<String, int> stats) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildStatCard('Sent', stats['sent'] ?? 0, Colors.green),
          const SizedBox(width: 12),
          _buildStatCard('Failed', stats['failed'] ?? 0, Colors.red),
          const SizedBox(width: 12),
          _buildStatCard('Pending', stats['pending'] ?? 0, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: StatCard(
        label: label,
        value: '$count',
        color: color,
      ),
    );
  }

  Widget _buildLogsTable(List<SmsLogModel> logs) {
    final simsAsync = ref.watch(simsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Receiver')),
            DataColumn(label: Text('Message')),
            DataColumn(label: Text('SIM')),
            DataColumn(label: Text('Status')),
          ],
          rows: logs.map((log) {
            String simLabel = log.simId ?? '-';
            simsAsync.whenData((sims) {
              try {
                final sim = sims.firstWhere((s) => s.id == log.simId);
                simLabel = sim.carrierName;
              } catch (_) {}
            });

            return DataRow(
              cells: [
                DataCell(Text(DateFormat('dd MMM, hh:mm a').format(log.createdAt))),
                DataCell(Text(log.receiverNumber)),
                DataCell(
                  Container(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      log.message,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(simLabel)),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatusBadge(status: log.status),
                      if (log.status == 'failed' && log.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            log.errorMessage!,
                            style: const TextStyle(fontSize: 9, color: Colors.red),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyStateWidget(
      icon: Icons.notes_rounded,
      title: 'No SMS records found',
      description: 'Try adjusting your date range or SIM filter.',
    );
  }
}
