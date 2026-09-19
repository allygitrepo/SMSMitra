import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/bulk_recipient_model.dart';
import '../providers/bulk_sms_provider.dart';
import '../../../core/helpers/snackbar_helper.dart';

/// Modal bottom sheet allowing users to view, search, edit, and delete recipients from the current campaign list.
class RecipientsListSheet extends ConsumerStatefulWidget {
  const RecipientsListSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RecipientsListSheet(),
    );
  }

  @override
  ConsumerState<RecipientsListSheet> createState() => _RecipientsListSheetState();
}

class _RecipientsListSheetState extends ConsumerState<RecipientsListSheet> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showEditRecipientDialog(int originalIndex, BulkRecipientModel recipient) {
    final nameController = TextEditingController(text: recipient.name);
    final phoneController = TextEditingController(text: recipient.phone);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Edit Recipient', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter mobile number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();
              if (newPhone.isNotEmpty) {
                ref.read(bulkSmsProvider.notifier).updateRecipient(
                  originalIndex,
                  name: newName,
                  phone: newPhone,
                );
                Navigator.pop(dialogCtx);
                MessageHelper.showSuccess(context, 'Recipient updated');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(bulkSmsProvider);
    final recipients = state.recipients;

    final filtered = recipients.asMap().entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final r = entry.value;
      return r.name.toLowerCase().contains(q) || r.phone.toLowerCase().contains(q);
    }).toList();

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.people_alt_rounded, color: colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Imported Recipients',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${recipients.length} total recipients in campaign',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (recipients.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            ref.read(bulkSmsProvider.notifier).clearRecipients();
                            Navigator.pop(context);
                            MessageHelper.showSuccess(context, 'Cleared all recipients');
                          },
                          icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.red),
                          label: const Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by name or number...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List of Recipients
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            recipients.isEmpty ? 'No recipients loaded yet' : 'No matching recipients found',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recipients.isEmpty
                                ? 'Import CSV contacts or select from your address book.'
                                : 'Try searching for a different name or number.',
                            style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final entry = filtered[index];
                        final originalIndex = entry.key;
                        final recipient = entry.value;

                        final initials = (recipient.name.isNotEmpty)
                            ? recipient.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
                            : '#';

                        return Material(
                          color: theme.cardColor,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                              foregroundColor: colorScheme.primary,
                              child: Text(
                                initials,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                            ),
                            title: Text(
                              recipient.name.isNotEmpty ? recipient.name : 'Unknown Name',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  recipient.phone,
                                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                ),
                                if (recipient.customData.isNotEmpty && recipient.customData.length > 2) ...[
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: recipient.customData.entries
                                        .where((e) => e.key != 'name' && e.key != 'phone')
                                        .map((e) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '${e.key}: ${e.value}',
                                                style: const TextStyle(fontSize: 10, color: Colors.blue),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Edit Recipient',
                                  onPressed: () => _showEditRecipientDialog(originalIndex, recipient),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                  tooltip: 'Remove Recipient',
                                  onPressed: () {
                                    ref.read(bulkSmsProvider.notifier).removeRecipient(originalIndex);
                                    MessageHelper.showSuccess(context, 'Removed recipient');
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
