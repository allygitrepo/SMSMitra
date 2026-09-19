import 'package:flutter/material.dart';
import '../../../data/models/bulk_recipient_model.dart';

class RecipientPreviewSlider extends StatefulWidget {
  final List<BulkRecipientModel> recipients;
  final String templateMessage;
  final void Function(int index, String newName)? onEditName;

  const RecipientPreviewSlider({
    super.key,
    required this.recipients,
    required this.templateMessage,
    this.onEditName,
  });

  @override
  State<RecipientPreviewSlider> createState() => _RecipientPreviewSliderState();
}

class _RecipientPreviewSliderState extends State<RecipientPreviewSlider> {
  int _currentIndex = 0;

  void _showEditNameDialog(BuildContext context, int index, BulkRecipientModel recipient) {
    final controller = TextEditingController(text: recipient.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Edit Recipient Name', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile: ${recipient.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Contact Name',
                hintText: 'Enter name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              Navigator.pop(ctx);
              widget.onEditName?.call(index, newName);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recipients.isEmpty || widget.templateMessage.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final safeIndex = _currentIndex.clamp(0, widget.recipients.length - 1);
    final recipient = widget.recipients[safeIndex];
    final previewText = recipient.interpolateMessage(widget.templateMessage);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final initials = (recipient.name.isNotEmpty)
        ? recipient.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : '#';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.preview_rounded, size: 18, color: Colors.purple),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Live Personalization Preview',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${safeIndex + 1} / ${widget.recipients.length}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Message Preview Container (Chat bubble look)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF192231) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipient Header row in bubble
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.purple.withValues(alpha: 0.2),
                      child: Text(
                        initials,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.purple),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recipient.name.isNotEmpty ? recipient.name : 'Unknown Recipient',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.onEditName != null) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => _showEditNameDialog(context, safeIndex, recipient),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 13, color: Colors.blue),
                              SizedBox(width: 3),
                              Text('Edit', style: TextStyle(fontSize: 11, color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      recipient.phone,
                      style: TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: theme.textTheme.bodySmall?.color),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Interpolated Message Body
                SelectableText(
                  previewText,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stepper & Slider navigation
          Row(
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                onPressed: safeIndex > 0
                    ? () => setState(() => _currentIndex = safeIndex - 1)
                    : null,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: safeIndex.toDouble(),
                    min: 0,
                    max: (widget.recipients.length - 1).toDouble().clamp(0, double.infinity),
                    divisions: widget.recipients.length > 1 ? widget.recipients.length - 1 : 1,
                    onChanged: (val) => setState(() => _currentIndex = val.round()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                onPressed: safeIndex < widget.recipients.length - 1
                    ? () => setState(() => _currentIndex = safeIndex + 1)
                    : null,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
