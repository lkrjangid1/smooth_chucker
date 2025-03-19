import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget for displaying a key-value pair
class KeyValueWidget extends StatelessWidget {
  /// The key text
  final String keyText;

  /// The value text
  final String valueText;

  /// Whether the value can be copied
  final bool canCopy;

  /// Optional color for the value text
  final Color? valueColor;

  /// Constructor
  const KeyValueWidget({
    super.key,
    required this.keyText,
    required this.valueText,
    this.canCopy = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            keyText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  valueText,
                  style: TextStyle(
                    color: valueColor,
                  ),
                ),
              ),
              if (canCopy)
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => _copyToClipboard(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Copy value to clipboard
  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: valueText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $valueText'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
