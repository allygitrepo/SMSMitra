import 'package:flutter/material.dart';
import '../../../data/models/bulk_recipient_model.dart';

class RecipientPreviewSlider extends StatefulWidget {
  final List<BulkRecipientModel> recipients;
  final String templateMessage;

  const RecipientPreviewSlider({
    super.key,
    required this.recipients,
    required this.templateMessage,
  });

  @override
  State<RecipientPreviewSlider> createState() => _RecipientPreviewSliderState();
}

class _RecipientPreviewSliderState extends State<RecipientPreviewSlider> {
  int _currentIndex = 0;

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

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.preview_rounded, size: 16, color: Colors.purple),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live Personalization Preview',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                '${safeIndex + 1} of ${widget.recipients.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recipient Meta pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  recipient.name.isNotEmpty ? recipient.name : 'Unknown Name',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  recipient.phone,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Message Preview bubble
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              previewText,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Stepper Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                onPressed: safeIndex > 0
                    ? () => setState(() => _currentIndex = safeIndex - 1)
                    : null,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
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
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
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
