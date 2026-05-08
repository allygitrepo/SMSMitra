import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sms_app/features/home/stats_provider.dart';
import '../../core/utils/pdf_generator.dart';
import '../../features/reports/reports_provider.dart';
import '../../features/settings/settings_provider.dart';
import '../../data/services/socket_service.dart';
import 'dart:async';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  StreamSubscription<void>? _socketSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).init();
    });

    _socketSubscription = SocketService().statsUpdateStream.listen((_) {
      debugPrint("ReportsScreen: Received Socket stats update trigger");
      ref.read(reportsProvider.notifier).fetchReports();
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detailed Reports'),
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

  Widget _buildOrgFilter(BuildContext context, ReportsState state) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 45,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: state.orgCode ?? 'all',
            isDense: true,
            dropdownColor: theme.cardColor,
            icon: Icon(Icons.business, color: theme.primaryColor, size: 16),
            items: [
              const DropdownMenuItem(value: 'all', child: Text('All Types')),
              const DropdownMenuItem(value: 'none', child: Text('Personal')),
              ...state.organizations.map((org) => DropdownMenuItem(
                    value: org.orgCode,
                    child: Text(org.orgName),
                  )),
            ],
            onChanged: (val) {
              ref.read(reportsProvider.notifier).updateOrgFilter(val);
            },
            style: TextStyle(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    ReportsState state,
    dynamic settings,
  ) {
    final theme = Theme.of(context);
    final simsAsync = ref.watch(simsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.cardColor,
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
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
          ),
          const SizedBox(width: 12),
          _buildOrgFilter(context, state),
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
                  items: [
                    DropdownMenuItem<String>(
                      value: 'all',
                      child: Text(
                        'All SIMs',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    ...settings.simPriority.map((simId) {
                      String label =
                          'SIM ${settings.simPriority.indexOf(simId) + 1}';

                      // Try to find the carrier name from detected sims
                      simsAsync.whenData((sims) {
                        try {
                          final sim = sims.firstWhere((s) => s.id == simId);
                          label = sim.carrierName;
                        } catch (_) {}
                      });

                      return DropdownMenuItem<String>(
                        value: simId.toString(),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTable(List<dynamic> logs) {
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
            DataColumn(label: Text('Org')),
            DataColumn(label: Text('Status')),
          ],
          rows: logs.map((log) {
            final dateStr = log['createdAt']?.toString() ?? '';
            // Ignore 'Z' suffix to show exact DB time without timezone conversion
            final date = DateTime.parse(dateStr.replaceAll('Z', ''));

            String simLabel = log['simId']?.toString() ?? '-';
            simsAsync.whenData((sims) {
              try {
                final sim = sims.firstWhere((s) => s.id == log['simId']?.toString());
                simLabel = sim.carrierName;
              } catch (_) {}
            });

            return DataRow(
              cells: [
                DataCell(Text(DateFormat('dd MMM, hh:mm a').format(date))),
                DataCell(Text(log['receiverNumber'] ?? '')),
                DataCell(
                  Container(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: Text(
                      log['message'] ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(simLabel)),
                DataCell(Text(log['orgCode'] ?? '-')),
                DataCell(_buildStatusChip(log['status'])),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color = Colors.grey;
    if (status == 'sent') color = Colors.green;
    if (status == 'failed') color = Colors.red;
    if (status == 'pending') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status?.toUpperCase() ?? 'UNKNOWN',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notes, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'No records found for the selected filters',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
