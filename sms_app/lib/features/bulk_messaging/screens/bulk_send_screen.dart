import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/bulk_messaging_provider.dart';
import '../../../data/models/bulk_recipient_model.dart';
import '../../../data/models/organization_model.dart';
import '../../../data/models/template_model.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/services/whatsapp_sms_service.dart';

class BulkSendScreen extends ConsumerStatefulWidget {
  const BulkSendScreen({super.key});

  @override
  ConsumerState<BulkSendScreen> createState() => _BulkSendScreenState();
}

class _BulkSendScreenState extends ConsumerState<BulkSendScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isManualEntry = false;
  final _whatsappService = WhatsAppSmsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bulkMessagingProvider.notifier).init();
      _whatsappService.init(); // Initialize WhatsApp service
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bulkMessagingProvider);
    final notifier = ref.read(bulkMessagingProvider.notifier);

    // Update message controller if template changes
    if (_messageController.text != state.message) {
      _messageController.text = state.message;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Messaging'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => notifier.clearRecipients(),
            tooltip: 'Clear All Recipients',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrganizationSelector(state, notifier),
                  const SizedBox(height: 16),
                  _buildChannelSelector(state, notifier),
                  const SizedBox(height: 16),
                  _buildTemplateSelector(state, notifier),
                  const SizedBox(height: 16),
                  _buildMessageComposer(state, notifier),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add Recipients',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      _buildEntryTypeToggle(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // if (state.channel == 'telegram')
                  //   _buildTelegramSection(state, notifier)
                  /* else */ if (_isManualEntry)
                    _buildManualEntryCard(notifier)
                  else
                    _buildUploadCard(notifier),
                  const SizedBox(height: 16),
                  _buildRecipientList(state, notifier),
                  const SizedBox(height: 80), // Space for button
                ],
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: GradientButton(
          text: 'Send to ${state.recipients.length} Recipients',
          onPressed: state.recipients.isEmpty || state.message.isEmpty
              ? null
              : () => _showProgressDialog(context),
        ),
      ),
    );
  }

  Widget _buildEntryTypeToggle() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toggleItem(label: 'Manual', value: true),
            const SizedBox(width: 4),
            _toggleItem(label: 'CSV', value: false),
          ],
        ),
      ),
    );
  }

  Widget _toggleItem({required String label, required bool value}) {
    final isSelected = _isManualEntry == value;
    return InkWell(
      onTap: () => setState(() => _isManualEntry = value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildChannelSelector(
      BulkMessagingState state, BulkMessagingNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Communication Channel',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                /* if (state.channel == 'telegram')
                  TextButton.icon(
                    onPressed: () async {
                      const url = 'https://t.me/smsmitra_bot'; // adjust bot URL
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.telegram, size: 16),
                    label: const Text('Connect Telegram',
                        style: TextStyle(fontSize: 12)),
                  ), */
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.orange,
                selectedForegroundColor: Colors.white,
                foregroundColor: Colors.grey.shade600,
              ),
              segments: [
                const ButtonSegment(
                  value: 'sms',
                  label: Text('SMS'),
                  icon: Icon(Icons.sms_outlined),
                ),
                ButtonSegment(
                  value: 'whatsapp',
                  label: const Text('WhatsApp'),
                  icon: Image.asset(
                    'assets/whatsapp.webp',
                    height: 20,
                    color: state.channel == 'whatsapp'
                        ? Colors.white
                        : Colors.grey.shade600,
                  ),
                ),
              ],
              selected: {state.channel},
              onSelectionChanged: (Set<String> newSelection) {
                final channel = newSelection.first;
                if (channel == 'whatsapp' && !_whatsappService.isLinked()) {
                  MessageHelper.showWarning(
                    context,
                    'WhatsApp is not linked. Please link it in Settings first.',
                  );
                }
                notifier.setChannel(channel);
              },
            ),
          ],
        ),
      ),
    );
  }

  /* Widget _buildTelegramSection(
      BulkMessagingState state, BulkMessagingNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Telegram Contacts',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  onPressed: () => notifier.fetchTelegramContacts(),
                  icon: const Icon(Icons.refresh,
                      size: 20, color: AppColors.orange),
                )
              ],
            ),
            const SizedBox(height: 12),
            if (state.telegramContacts.isEmpty)
              const Text('No Telegram contacts found. Please connect bot.',
                  style: TextStyle(color: Colors.grey))
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.telegramContacts.length,
                  itemBuilder: (context, index) {
                    final contact = state.telegramContacts[index];
                    final isAdded = state.recipients
                        .any((r) => r.phone == contact.telegramChatId);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.telegram)),
                      title: Text(contact.name),
                      subtitle: Text(
                          contact.telegramUsername ?? contact.telegramChatId),
                      trailing: isAdded
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: AppColors.orange),
                              onPressed: () =>
                                  notifier.addTelegramRecipient(contact),
                            ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  } */

  Widget _buildOrganizationSelector(
      BulkMessagingState state, BulkMessagingNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Organization',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => _showAddOrgBottomSheet(context),
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.orange, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Add New Organization',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Autocomplete<OrganizationModel>(
              displayStringForOption: (option) => option.orgName,
              initialValue:
                  TextEditingValue(text: state.selectedOrg?.orgName ?? ''),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return state.organizations;
                }
                return state.organizations.where((org) {
                  return org.orgName
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (option) {
                notifier.selectOrganization(option);
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search or select organization...',
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              controller.clear();
                              notifier.selectOrganization(null);
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(BulkMessagingNotifier notifier) {
    return Card(
      child: InkWell(
        onTap: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['csv', 'xls', 'xlsx'],
          );

          if (result != null) {
            notifier.parseFile(result.files.single.path!);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.orange,
                child: Icon(Icons.upload_file, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Upload CSV / Excel',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Support .csv, .xls, .xlsx',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => notifier.downloadTemplate(),
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Template', style: TextStyle(fontSize: 12)),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryCard(BulkMessagingNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manual Entry',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(hintText: 'Name', isDense: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                        hintText: 'Mobile', isDense: true),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    if (_nameController.text.isNotEmpty &&
                        _phoneController.text.isNotEmpty) {
                      notifier.addRecipient(
                          _nameController.text, _phoneController.text);
                      _nameController.clear();
                      _phoneController.clear();
                    }
                  },
                  icon: const Icon(Icons.add_circle, color: AppColors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateSelector(
      BulkMessagingState state, BulkMessagingNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Message Template',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => _showAddTemplateBottomSheet(context),
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.orange, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Add New Template',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Autocomplete<SmsTemplateModel>(
              displayStringForOption: (option) => option.templateName,
              initialValue: TextEditingValue(
                  text: state.selectedTemplate?.templateName ?? ''),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return state.templates;
                }
                return state.templates.where((t) {
                  return t.templateName
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (option) {
                notifier.selectTemplate(option);
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Search or select template...',
                    border: const OutlineInputBorder(),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              controller.clear();
                              notifier.selectTemplate(null);
                              _messageController.clear();
                              notifier.updateMessage('');
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer(
      BulkMessagingState state, BulkMessagingNotifier notifier) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Message Body',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () {
                    final pos = _messageController.selection.baseOffset;
                    final text = _messageController.text;
                    final newText = text.replaceRange(
                        pos != -1 ? pos : text.length,
                        pos != -1 ? pos : text.length,
                        '{name}');
                    _messageController.text = newText;
                    notifier.updateMessage(newText);
                  },
                  child: const Text('{name}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter your message here...',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => notifier.updateMessage(val),
            ),
            const SizedBox(height: 8),
            Text(
              'Characters: ${_messageController.text.length} | Parts: ${(_messageController.text.length / 160).ceil()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientList(
      BulkMessagingState state, BulkMessagingNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Recipients (${state.recipients.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        if (state.recipients.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No recipients added yet',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.recipients.length,
            itemBuilder: (context, index) {
              final r = state.recipients[index];
              return ListTile(
                leading:
                    const CircleAvatar(child: Icon(Icons.person, size: 20)),
                title: Text(r.name),
                subtitle: Text(r.phone),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => notifier.removeRecipient(index),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BulkProgressDialog(),
    );

    // Start sending
    ref.read(bulkMessagingProvider.notifier).sendBulkMessages();
  }

  void _showAddOrgBottomSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    File? selectedLogo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Organization',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Organization Name*',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Office Address',
                      border: OutlineInputBorder()),
                  maxLines: 2),
              const SizedBox(height: 20),
              // const Text('Organization Logo', style: TextStyle(fontWeight: FontWeight.bold)),
              // const SizedBox(height: 8),
              // InkWell(
              //   onTap: () async {
              //     FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
              //     if (result != null) {
              //       setState(() => selectedLogo = File(result.files.single.path!));
              //     }
              //   },
              //   child: Container(
              //     height: 100,
              //     width: double.infinity,
              //     decoration: BoxDecoration(
              //       border: Border.all(color: Colors.grey.shade300),
              //       borderRadius: BorderRadius.circular(10),
              //       color: Colors.grey.shade50,
              //     ),
              //     child: selectedLogo == null
              //         ? Column(
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             children: const [
              //               Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
              //               Text('Click to select logo', style: TextStyle(color: Colors.grey, fontSize: 12)),
              //             ],
              //           )
              //         : ClipRRect(
              //             borderRadius: BorderRadius.circular(10),
              //             child: Image.file(selectedLogo!, fit: BoxFit.cover),
              //           ),
              //   ),
              // ),
              const SizedBox(height: 24),
              GradientButton(
                text: 'Create Organization',
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    try {
                      await ref
                          .read(bulkMessagingProvider.notifier)
                          .createOrganization(
                            name: nameCtrl.text,
                            email: emailCtrl.text,
                            address: addrCtrl.text,
                            logo: selectedLogo,
                          );
                      if (context.mounted) {
                        MessageHelper.showSuccess(
                            context, 'Organization created successfully!');
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        MessageHelper.showError(context, e);
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTemplateBottomSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Message Template',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Template Name*', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
              controller: msgCtrl,
              decoration: const InputDecoration(
                labelText: 'Message Body*',
                hintText: 'Use {name} for personalization',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Save Template',
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                  try {
                    await ref
                        .read(bulkMessagingProvider.notifier)
                        .createTemplate(nameCtrl.text, msgCtrl.text);
                    if (context.mounted) {
                      MessageHelper.showSuccess(
                          context, 'Template saved successfully!');
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      MessageHelper.showError(context, e);
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class BulkProgressDialog extends ConsumerWidget {
  const BulkProgressDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bulkMessagingProvider);
    final total = state.recipients.length;
    final processed = state.sentCount + state.failedCount;
    final progress = total > 0 ? processed / total : 0.0;

    return AlertDialog(
      title: const Text('Sending Messages'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 16),
          Text('$processed / $total processed'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Sent: ${state.sentCount}',
                  style: const TextStyle(color: Colors.green)),
              Text('Failed: ${state.failedCount}',
                  style: const TextStyle(color: Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: state.recipients.length,
              itemBuilder: (context, index) {
                final r = state.recipients[index];
                IconData icon = Icons.pending_outlined;
                Color color = Colors.grey;

                if (r.status == RecipientStatus.sending) {
                  icon = Icons.send;
                  color = Colors.blue;
                } else if (r.status == RecipientStatus.sent) {
                  icon = Icons.check_circle;
                  color = Colors.green;
                } else if (r.status == RecipientStatus.failed) {
                  icon = Icons.error;
                  color = Colors.red;
                }

                return ListTile(
                  dense: true,
                  leading: Icon(icon, color: color, size: 20),
                  title: Text(r.name),
                  subtitle: Text(
                    r.status == RecipientStatus.failed && r.error != null
                        ? '${r.phone}\nError: ${r.error}'
                        : r.phone,
                    style: TextStyle(
                      color: r.status == RecipientStatus.failed
                          ? Colors.red.shade700
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: state.isSending
              ? null
              : () {
                  ref.read(bulkMessagingProvider.notifier).reset();
                  Navigator.pop(context);
                },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
