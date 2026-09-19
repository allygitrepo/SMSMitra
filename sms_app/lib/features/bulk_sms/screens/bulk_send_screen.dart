import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/helpers/validation_helper.dart';
import '../../../data/models/bulk_recipient_model.dart';
import '../../../data/models/sim_model.dart';
import '../../../data/services/bulk_sms_service.dart';
import '../../contacts/widgets/contact_picker_sheet.dart';
import '../../home/stats_provider.dart';
import '../providers/bulk_sms_provider.dart';
import '../widgets/placeholder_picker.dart';
import '../widgets/recipient_preview_slider.dart';
import '../widgets/bulk_progress_dialog.dart';
import '../widgets/templates_sheet.dart';
import '../widgets/recipients_list_sheet.dart';

class BulkSendScreen extends ConsumerStatefulWidget {
  const BulkSendScreen({super.key});

  @override
  ConsumerState<BulkSendScreen> createState() => _BulkSendScreenState();
}

class _BulkSendScreenState extends ConsumerState<BulkSendScreen> {
  final _messageController = TextEditingController();
  final _phoneInputController = TextEditingController();
  final _nameInputController = TextEditingController();
  final _manualFormKey = GlobalKey<FormState>();
  bool _showManualAdd = false;

  @override
  void dispose() {
    _messageController.dispose();
    _phoneInputController.dispose();
    _nameInputController.dispose();
    super.dispose();
  }

  Future<void> _handlePickContactsMulti() async {
    final existingPhones = ref.read(bulkSmsProvider).recipients.map((r) => r.phone).toSet();
    final selectedContacts = await ContactPickerSheet.showMulti(
      context,
      initiallySelectedPhones: existingPhones,
    );

    if (selectedContacts != null && selectedContacts.isNotEmpty && mounted) {
      final recipients = selectedContacts.map((c) => BulkRecipientModel(
        phone: c.phone,
        name: c.name,
        customData: {'name': c.name, 'phone': c.phone},
      )).toList();

      ref.read(bulkSmsProvider.notifier).addMultipleRecipients(recipients);
      MessageHelper.showSuccess(context, 'Imported ${selectedContacts.length} contacts');
    }
  }

  Future<void> _handlePickContactSingle() async {
    final contact = await ContactPickerSheet.showSingle(context);
    if (contact != null && mounted) {
      final raw = contact.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final phone10 = raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
      _phoneInputController.text = phone10;
      _nameInputController.text = contact.name;
      MessageHelper.showSuccess(context, 'Selected ${contact.name}');
    }
  }

  Future<void> _pickAndParseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt', 'tsv'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final ok = await ref.read(bulkSmsProvider.notifier).parseFile(path);
        if (ok && mounted) {
          final count = ref.read(bulkSmsProvider).recipients.length;
          MessageHelper.showSuccess(context, 'Imported $count recipients successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(context, 'Failed to import file: $e');
      }
    }
  }

  Future<void> _handleDownloadCsvTemplate() async {
    try {
      final path = await BulkSmsService.downloadSampleCsvTemplate();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.file_download_done_rounded, color: Colors.green, size: 22),
              ),
              const SizedBox(width: 10),
              const Text('Sample CSV Template', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Standard multi-column sample template for SMS Mitra is ready:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogCtx).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(dialogCtx).dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Headers included:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      const Text('phone, name, amount, dueDate, invoiceNo', style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                      const Text('Local saved path:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 2),
                      SelectableText(
                        path,
                        style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await Printing.sharePdf(
                  bytes: Uint8List.fromList(utf8.encode(BulkSmsService.sampleCsvTemplate)),
                  filename: 'smsmitra_sample_template.csv',
                );
              },
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Save / Share File'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(text: BulkSmsService.sampleCsvTemplate));
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  MessageHelper.showSuccess(dialogCtx, 'Sample CSV copied to clipboard');
                }
              },
              child: const Text('Copy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                ref.read(bulkSmsProvider.notifier).parseRawText(BulkSmsService.sampleCsvTemplate);
                final count = ref.read(bulkSmsProvider).recipients.length;
                MessageHelper.showSuccess(context, 'Loaded $count sample recipients');
              },
              child: const Text('Load in App'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(context, 'Failed to prepare template: $e');
      }
    }
  }

  void _handleManualAdd() {
    if (_manualFormKey.currentState!.validate()) {
      final phone = _phoneInputController.text.trim();
      final name = _nameInputController.text.trim();

      ref.read(bulkSmsProvider.notifier).addRecipient(
        BulkRecipientModel(
          phone: phone,
          name: name,
          customData: {
            'phone': phone,
            if (name.isNotEmpty) 'name': name,
          },
        ),
      );

      _phoneInputController.clear();
      _nameInputController.clear();
      MessageHelper.showSuccess(context, 'Recipient added');
    }
  }

  void _handleStartCampaign() {
    final state = ref.read(bulkSmsProvider);
    if (state.recipients.isEmpty) {
      MessageHelper.showError(context, 'Please add or import recipients first');
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      MessageHelper.showError(context, 'Please enter an SMS message body');
      return;
    }

    ref.read(bulkSmsProvider.notifier).setMessage(_messageController.text.trim());

    // Show sending progress dialog
    BulkProgressDialog.show(context);

    // Start sending
    ref.read(bulkSmsProvider.notifier).startSending(
      onComplete: () {
        if (mounted) {
          final summary = ref.read(bulkSmsProvider).summaryMessage;
          MessageHelper.showSuccess(context, summary ?? 'Bulk campaign completed!');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkSmsProvider);
    final notifier = ref.read(bulkSmsProvider.notifier);
    final simsAsync = ref.watch(simsProvider);

    // Listen for template selection to update text controller
    ref.listen<String>(bulkSmsProvider.select((s) => s.message), (prev, next) {
      if (_messageController.text != next) {
        _messageController.text = next;
      }
    });

    final charCount = _messageController.text.length;
    final partsCount = charCount == 0 ? 1 : (charCount / 160).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk SMS Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'Saved Templates',
            onPressed: () => TemplatesSheet.show(
              context,
              onSelect: (tpl) {
                notifier.selectTemplate(tpl);
                _messageController.text = tpl.templateMessage;
              },
            ),
          ),
          if (state.recipients.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              tooltip: 'View All Recipients',
              onPressed: () => RecipientsListSheet.show(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              tooltip: 'Clear All Recipients',
              onPressed: () {
                notifier.clearRecipients();
                MessageHelper.showSuccess(context, 'Cleared all recipients');
              },
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Step 1: Ingest Recipients Hub ────────────────────────
            _buildRecipientsHub(context, state),

            const SizedBox(height: 18),

            // ── Live Personalization Preview Slider ───────────────────
            if (state.recipients.isNotEmpty && _messageController.text.trim().isNotEmpty) ...[
              RecipientPreviewSlider(
                recipients: state.recipients,
                templateMessage: _messageController.text,
                onEditName: (index, newName) {
                  notifier.updateRecipient(index, name: newName);
                  MessageHelper.showSuccess(context, 'Updated contact name: $newName');
                },
              ),
              const SizedBox(height: 18),
            ],

            // ── Step 2: Message Composer ─────────────────────────────
            _buildComposerCard(context, state, notifier, charCount, partsCount),

            const SizedBox(height: 18),

            // ── Step 3: Gateway & Throttling ─────────────────────────
            _buildGatewayCard(context, state, notifier, simsAsync),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(context, state),
    );
  }

  // ── Step 1: Recipients Hub ──────────────────────────────────────────────────

  Widget _buildRecipientsHub(BuildContext context, BulkSmsState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recipientCount = state.recipients.length;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.group_rounded, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '1. Target Audience',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: recipientCount > 0
                      ? colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  recipientCount > 0 ? '$recipientCount Ready' : '0 Added',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: recipientCount > 0 ? colorScheme.primary : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Active Summary Banner if contacts are loaded
          if (recipientCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$recipientCount Recipients Configured',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                        if (state.discoveredColumns.length > 2)
                          Text(
                            'Variables: ${state.discoveredColumns.join(', ')}',
                            style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => RecipientsListSheet.show(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('View / Manage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Ingestion Action Buttons Grid
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.contacts_rounded,
                  label: 'From Contacts',
                  color: colorScheme.primary,
                  onTap: _handlePickContactsMulti,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.upload_file_rounded,
                  label: state.isParsing ? 'Parsing CSV...' : 'Upload CSV',
                  color: Colors.teal,
                  isLoading: state.isParsing,
                  onTap: state.isParsing ? null : _pickAndParseFile,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildActionTile(
            icon: _showManualAdd ? Icons.close_rounded : Icons.person_add_rounded,
            label: _showManualAdd ? 'Close Manual Input' : 'Add Single Recipient',
            color: Colors.indigo,
            onTap: () => setState(() => _showManualAdd = !_showManualAdd),
          ),

          // Inline Single Recipient Form
          if (_showManualAdd) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
              ),
              child: Form(
                key: _manualFormKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _phoneInputController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number *',
                              hintText: '9876543210',
                              prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.contacts_rounded, size: 18, color: colorScheme.primary),
                                tooltip: 'Select Contact',
                                onPressed: _handlePickContactSingle,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            validator: ValidationHelper.validatePhone,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _nameInputController,
                            decoration: InputDecoration(
                              labelText: 'Name (Optional)',
                              hintText: 'John Doe',
                              prefixIcon: const Icon(Icons.person_outline, size: 18),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _handleManualAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add to Campaign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Download CSV Template Pill
          Center(
            child: TextButton.icon(
              onPressed: _handleDownloadCsvTemplate,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.download_rounded, size: 16, color: Colors.teal),
              label: const Text(
                'Download Sample CSV Template',
                style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? color.withValues(alpha: 0.1) : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color),
                )
              else
                Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 2: Message Composer ────────────────────────────────────────────────

  Widget _buildComposerCard(
    BuildContext context,
    BulkSmsState state,
    BulkSmsNotifier notifier,
    int charCount,
    int partsCount,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '2. Message Composer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => TemplatesSheet.show(
                  context,
                  onSelect: (tpl) {
                    notifier.selectTemplate(tpl);
                    _messageController.text = tpl.templateMessage;
                  },
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.bookmark_outline_rounded, size: 16, color: Colors.teal),
                label: const Text('Templates', style: TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dynamic Placeholder Picker
          PlaceholderPicker(
            columns: state.discoveredColumns,
            onSelected: (col) {
              notifier.insertPlaceholder(
                placeholder: col,
                controller: _messageController,
              );
            },
          ),
          const SizedBox(height: 12),

          // Text Field
          TextField(
            controller: _messageController,
            maxLines: 5,
            onChanged: (val) => notifier.setMessage(val),
            decoration: InputDecoration(
              hintText: 'Type your message... e.g. Hello {name}, your amount of Rs.{amount} is due on {dueDate}.',
              hintStyle: const TextStyle(fontSize: 13),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Counters Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$charCount chars',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: partsCount > 1
                      ? Colors.orange.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$partsCount SMS Part${partsCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: partsCount > 1 ? Colors.orange : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Step 3: Gateway & Throttling ────────────────────────────────────────────

  Widget _buildGatewayCard(
    BuildContext context,
    BulkSmsState state,
    BulkSmsNotifier notifier,
    AsyncValue<List<SimModel>> simsAsync,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sim_card_rounded, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                '3. Gateway & Speed',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // SIM Dropdown
          simsAsync.when(
            data: (sims) {
              if (sims.isEmpty) {
                return const Text('No SIM cards detected on device.', style: TextStyle(color: Colors.grey));
              }
              return DropdownButtonFormField<String>(
                initialValue: state.selectedSimId ?? (sims.isNotEmpty ? sims.first.id : null),
                decoration: InputDecoration(
                  labelText: 'Outbound SIM Gateway',
                  prefixIcon: const Icon(Icons.sim_card_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                items: sims.map((sim) {
                  return DropdownMenuItem<String>(
                    value: sim.id,
                    child: Text('${sim.carrierName} (${sim.number.isNotEmpty ? sim.number : 'Slot ${sim.slotIndex + 1}'})'),
                  );
                }).toList(),
                onChanged: (val) => notifier.setSelectedSim(val),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Unable to read SIM cards'),
          ),

          const SizedBox(height: 14),

          // Throttle slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dispatch Rate: ${state.delayMs}ms / SMS',
                style: TextStyle(fontSize: 12.5, color: theme.textTheme.bodySmall?.color),
              ),
              Text(
                '⚡ ~${((1000 / (state.delayMs + 100)) * 60).round()} SMS/min',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          Slider(
            value: state.delayMs.toDouble(),
            min: 300,
            max: 2000,
            divisions: 17,
            label: '${state.delayMs}ms',
            onChanged: (val) => notifier.setDelay(val.round()),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action Bar ───────────────────────────────────────────────────────

  Widget _buildBottomActionBar(BuildContext context, BulkSmsState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canLaunch = state.recipients.isNotEmpty && _messageController.text.trim().isNotEmpty && !state.isSending;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton.icon(
          onPressed: canLaunch ? _handleStartCampaign : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          icon: const Icon(Icons.send_rounded, size: 20),
          label: Text(
            state.recipients.isEmpty
                ? 'Add Recipients to Launch'
                : _messageController.text.trim().isEmpty
                    ? 'Enter Message to Launch'
                    : 'Launch Campaign (${state.recipients.length} SMS)',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
