import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bulk_sms_provider.dart';

class BulkProgressDialog extends ConsumerWidget {
  const BulkProgressDialog({super.key});

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BulkProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bulkSmsProvider);
    final notifier = ref.read(bulkSmsProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final total = state.totalRecipients;
    final current = state.currentIndex;
    final isDone = !state.isSending;

    final currentRecipient = (current > 0 && current <= state.recipients.length)
        ? state.recipients[current - 1]
        : null;

    return PopScope(
      canPop: isDone,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.green.withValues(alpha: 0.15)
                          : colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDone ? Icons.check_circle_rounded : Icons.send_rounded,
                      color: isDone ? Colors.green : colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDone ? 'Campaign Finished' : (state.isPaused ? 'Campaign Paused' : 'Dispatching Campaign...'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          isDone ? 'All recipients processed' : 'Sending via cellular SIM',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Progress Bar & Percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress: $current / $total',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    '${(state.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 8,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone ? Colors.green : colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sent / Failed Badges
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SUCCESS',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.sentCount.toString(),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'FAILED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.failedCount.toString(),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Currently sending contact
              if (!isDone && currentRecipient != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sending to: ${currentRecipient.name.isNotEmpty ? currentRecipient.name : currentRecipient.phone}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Actions
              if (isDone) ...[
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.isPaused
                            ? () => notifier.resumeSending()
                            : () => notifier.pauseSending(),
                        icon: Icon(state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18),
                        label: Text(state.isPaused ? 'Resume' : 'Pause'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          notifier.cancelSending();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.stop_rounded, size: 18),
                        label: const Text('Stop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
