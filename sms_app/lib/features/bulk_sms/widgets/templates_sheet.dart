import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../data/models/template_model.dart';
import '../providers/template_provider.dart';
import '../providers/bulk_sms_provider.dart';

class TemplatesSheet extends ConsumerStatefulWidget {
  final void Function(SmsTemplateModel template)? onSelect;

  const TemplatesSheet({
    super.key,
    this.onSelect,
  });

  static void show(BuildContext context, {void Function(SmsTemplateModel template)? onSelect}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TemplatesSheet(onSelect: onSelect),
    );
  }

  @override
  ConsumerState<TemplatesSheet> createState() => _TemplatesSheetState();
}

class _TemplatesSheetState extends ConsumerState<TemplatesSheet> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateEditDialog([SmsTemplateModel? existing]) {
    final nameController = TextEditingController(text: existing?.templateName);
    final messageController = TextEditingController(text: existing?.templateMessage);
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (innerCtx, setDialogState) {
          final theme = Theme.of(innerCtx);
          final colorScheme = theme.colorScheme;

          void insertPlaceholder(String tag) {
            final text = messageController.text;
            final selection = messageController.selection;
            final insert = '{$tag}';
            String newText;
            int newPos;

            if (selection.start >= 0 && selection.end >= 0) {
              newText = text.replaceRange(selection.start, selection.end, insert);
              newPos = selection.start + insert.length;
            } else {
              newText = text + insert;
              newPos = newText.length;
            }

            messageController.text = newText;
            messageController.selection = TextSelection.collapsed(offset: newPos);
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  existing != null ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  existing != null ? 'Edit SMS Template' : 'New SMS Template',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Template Name',
                        hintText: 'e.g. Payment Reminder, Order Alert',
                        prefixIcon: const Icon(Icons.title_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter template name' : null,
                    ),
                    const SizedBox(height: 14),

                    // Quick Variable Chips
                    Text(
                      'Insert Placeholders:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ['name', 'phone', 'amount', 'dueDate', 'orderId', 'city'].map((tag) {
                        return ActionChip(
                          label: Text('{$tag}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                          onPressed: () => insertPlaceholder(tag),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Message Body',
                        hintText: 'Dear {name}, your balance of Rs.{amount} is due on {dueDate}.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter template message' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final name = nameController.text.trim();
                    final msg = messageController.text.trim();
                    Navigator.pop(dialogCtx);

                    if (existing != null) {
                      final ok = await ref.read(templateProvider.notifier).updateTemplate(
                        id: existing.id!,
                        name: name,
                        message: msg,
                      );
                      if (ok && mounted) {
                        MessageHelper.showSuccess(context, 'Template updated successfully!');
                      }
                    } else {
                      final ok = await ref.read(templateProvider.notifier).createTemplate(
                        name: name,
                        message: msg,
                      );
                      if (ok && mounted) {
                        MessageHelper.showSuccess(context, 'Template created successfully!');
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(existing != null ? 'Save' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(templateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filtered = state.templates.where((t) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return t.templateName.toLowerCase().contains(q) || t.templateMessage.toLowerCase().contains(q);
    }).toList();

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: Colors.teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bookmark_outline_rounded, color: Colors.teal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SMS Templates',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            '${state.templates.length} saved templates',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded, color: Colors.teal, size: 28),
                      tooltip: 'New Template',
                      onPressed: () => _showCreateEditDialog(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Box
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
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

          // Template List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'No templates found',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the + button to create your first reusable template.',
                              style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final template = filtered[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      template.templateName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: 'Edit Template',
                                    onPressed: () => _showCreateEditDialog(template),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                    tooltip: 'Delete Template',
                                    onPressed: () async {
                                      final ok = await ref.read(templateProvider.notifier).deleteTemplate(template.id!);
                                      if (ok && context.mounted) {
                                        MessageHelper.showSuccess(context, 'Template deleted');
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  template.templateMessage,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: theme.textTheme.bodySmall?.color,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              onTap: () {
                                if (widget.onSelect != null) {
                                  widget.onSelect!(template);
                                } else {
                                  ref.read(bulkSmsProvider.notifier).selectTemplate(template);
                                }
                                Navigator.pop(context);
                                MessageHelper.showSuccess(context, 'Applied template: ${template.templateName}');
                              },
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
