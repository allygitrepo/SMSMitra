import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/helpers/validation_helper.dart';
import '../../../data/models/sim_model.dart';
import '../../../data/services/bulk_sms_service.dart';
import '../../home/stats_provider.dart';
import '../providers/bulk_sms_provider.dart';
import '../widgets/placeholder_picker.dart';
import '../widgets/recipient_preview_slider.dart';
import '../widgets/bulk_progress_dialog.dart';
import '../widgets/templates_sheet.dart';

class BulkSendScreen extends ConsumerStatefulWidget {
  const BulkSendScreen({super.key});

  @override
  ConsumerState<BulkSendScreen> createState() => _BulkSendScreenState();
}

class _BulkSendScreenState extends ConsumerState<BulkSendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _messageController = TextEditingController();
  final _phoneInputController = TextEditingController();
  final _nameInputController = TextEditingController();
  final _pasteInputController = TextEditingController();
  final _manualFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _phoneInputController.dispose();
    _nameInputController.dispose();
    _pasteInputController.dispose();
    super.dispose();
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
                child: const Icon(Icons.download_done_rounded, color: Colors.green, size: 22),
              ),
              const SizedBox(width: 10),
              const Text('CSV Template Ready', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A sample CSV template has been generated with standard multi-column headers for SMSMitra.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
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
                      const Text('Saved file path:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
                      const SizedBox(height: 4),
                      SelectableText(
                        path,
                        style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Included Headers & Placeholders:\n'
                  '• {phone} - Recipient phone number\n'
                  '• {name} - Contact name\n'
                  '• {amount} - Dynamic bill/invoice amount\n'
                  '• {dueDate} - Due date reminder\n'
                  '• {invoiceNo} - Reference ID/order number',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(const ClipboardData(text: BulkSmsService.sampleCsvTemplate));
                MessageHelper.showSuccess(dialogCtx, 'Sample CSV copied to clipboard!');
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy CSV'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogCtx);
                ref.read(bulkSmsProvider.notifier).parseRawText(BulkSmsService.sampleCsvTemplate);
                MessageHelper.showSuccess(context, 'Sample template loaded into campaign!');
              },
              icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
              label: const Text('Load Sample Data'),
            ),
          ],
        ),
      );

      if (mounted) {
        MessageHelper.showSuccess(context, 'Template saved to Downloads');
      }
    } catch (e) {
      if (mounted) {
        MessageHelper.showError(context, 'Failed to download template: $e');
      }
    }
  }

  void _handleManualAdd() {
    if (_manualFormKey.currentState!.validate()) {
      final phone = _phoneInputController.text.trim();
      final name = _nameInputController.text.trim();

      ref.read(bulkSmsProvider.notifier).addManualRecipient(phone, name);
      _phoneInputController.clear();
      _nameInputController.clear();

      MessageHelper.showSuccess(context, 'Recipient added');
    }
  }

  void _handlePasteImport() {
    final text = _pasteInputController.text.trim();
    if (text.isEmpty) {
      MessageHelper.showError(context, 'Please paste CSV text or numbers');
      return;
    }

    ref.read(bulkSmsProvider.notifier).parseRawText(text);
    _pasteInputController.clear();
    Navigator.pop(context);
    MessageHelper.showSuccess(context, 'Contacts imported');
  }

  void _showPasteDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Paste Contacts / CSV'),
        content: TextField(
          controller: _pasteInputController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: "Phone,Name,Amount\n+919876543210,John,500\n9876543211,Jane,1200",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _handlePasteImport,
            child: const Text('Import'),
          ),
        ],
      ),
    );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        title: const Text('Bulk SMS Campaign'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'Templates',
            onPressed: () => TemplatesSheet.show(context),
          ),
          if (state.recipients.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              tooltip: 'Clear All Recipients',
              onPressed: () => notifier.clearRecipients(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Step 1: Ingest Recipients Card ────────────────────────
            _buildRecipientsCard(context, state),

            const SizedBox(height: 18),

            // ── Live Personalization Preview Slider ───────────────────
            if (state.recipients.isNotEmpty && _messageController.text.trim().isNotEmpty) ...[
              RecipientPreviewSlider(
                recipients: state.recipients,
                templateMessage: _messageController.text,
              ),
              const SizedBox(height: 18),
            ],

            // ── Step 2: Template Selector & Message Composer ──────────
            _buildComposerCard(context, state, notifier, charCount, partsCount),

            const SizedBox(height: 18),

            // ── Step 3: Dispatch Gateway Configuration ────────────────
            _buildGatewayCard(context, state, notifier, simsAsync),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: state.isSending ? null : _handleStartCampaign,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.send_rounded),
            label: Text(
              state.recipients.isEmpty
                  ? 'Start Campaign'
                  : 'Start Campaign (${state.recipients.length} SMS)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // ── Recipients Card ─────────────────────────────────────────────────────────

  Widget _buildRecipientsCard(BuildContext context, BulkSmsState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
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
                      '1. Add Recipients',
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
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${state.recipients.length} Added',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs: File Import vs Manual Input
          TabBar(
            controller: _tabController,
            indicatorColor: colorScheme.primary,
            labelColor: colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodySmall?.color,
            tabs: const [
              Tab(icon: Icon(Icons.upload_file_rounded, size: 18), text: 'Upload File (CSV)'),
              Tab(icon: Icon(Icons.edit_rounded, size: 18), text: 'Manual / Single'),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 195,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Upload File
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: state.isParsing ? null : _pickAndParseFile,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5)),
                        ),
                        icon: state.isParsing
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.file_upload_outlined),
                        label: Text(
                          state.isParsing ? 'Parsing Columns...' : 'Select CSV / Contacts File',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: _handleDownloadCsvTemplate,
                            icon: const Icon(Icons.file_download_outlined, size: 16),
                            label: const Text('Download CSV Template', style: TextStyle(fontSize: 12)),
                          ),
                          TextButton.icon(
                            onPressed: _showPasteDialog,
                            icon: const Icon(Icons.content_paste_rounded, size: 16),
                            label: const Text('Paste Raw CSV', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supports custom columns (Name, Phone, Amount, DueDate, etc.)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                      ),
                    ],
                  ),

                  // Tab 2: Manual Add
                  Form(
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
                                  labelText: 'Mobile Number *',
                                  hintText: '+919876543210',
                                  prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                validator: (v) => ValidationHelper.validatePhone(v),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _nameInputController,
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  hintText: 'John Doe',
                                  prefixIcon: const Icon(Icons.person_outline, size: 18),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _handleManualAdd,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Add Recipient'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Message Composer Card ───────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Template Button
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
                    child: const Icon(Icons.message_rounded, color: Colors.orange, size: 20),
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
              OutlinedButton.icon(
                onPressed: () => TemplatesSheet.show(
                  context,
                  onSelect: (tpl) {
                    notifier.selectTemplate(tpl);
                    _messageController.text = tpl.templateMessage;
                  },
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.bookmark_outline_rounded, size: 15),
                label: const Text('Templates', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic Placeholder Picker Bar
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

          // Message Text Area
          TextField(
            controller: _messageController,
            maxLines: 5,
            onChanged: (val) => notifier.setMessage(val),
            decoration: InputDecoration(
              hintText: 'Type your message here... Use {name}, {phone}, or column variables from above.',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Counters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$charCount characters',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

  // ── Gateway & Throttling Card ───────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
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
                '3. Gateway & SIM Slot',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // SIM Selector
          simsAsync.when(
            data: (sims) {
              if (sims.isEmpty) {
                return const Text('No SIM cards detected on device.');
              }
              return DropdownButtonFormField<String>(
                initialValue: state.selectedSimId ?? (sims.isNotEmpty ? sims.first.id : null),
                decoration: InputDecoration(
                  labelText: 'Dispatch SIM Card',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                items: sims.map((sim) {
                  return DropdownMenuItem<String>(
                    value: sim.id,
                    child: Text('${sim.carrierName} (Slot ${sim.slotIndex + 1})'),
                  );
                }).toList(),
                onChanged: (val) => notifier.setSelectedSim(val),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Unable to read SIM cards'),
          ),

          const SizedBox(height: 14),

          // Throttling Delay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dispatch Delay per SMS: ${state.delayMs}ms',
                style: TextStyle(fontSize: 12.5, color: theme.textTheme.bodySmall?.color),
              ),
              Text(
                '~${((1000 / (state.delayMs + 100)) * 60).round()} SMS/min',
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
}
