import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_json_viewer/flutter_json_viewer.dart';

/// Widget for displaying JSON data with controls
class JsonViewerPanel extends StatefulWidget {
  /// The JSON data to display
  final dynamic jsonData;

  /// Title of the panel
  final String title;

  /// Constructor
  const JsonViewerPanel({
    super.key,
    required this.jsonData,
    required this.title,
  });

  @override
  State<JsonViewerPanel> createState() => _JsonViewerPanelState();
}

class _JsonViewerPanelState extends State<JsonViewerPanel> {
  bool _isTreeView = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isTreeView ? Icons.code : Icons.account_tree,
                      ),
                      onPressed: () {
                        setState(() {
                          _isTreeView = !_isTreeView;
                        });
                      },
                      tooltip: _isTreeView ? 'Show as text' : 'Show as tree',
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyJson,
                      tooltip: 'Copy to clipboard',
                    ),
                  ],
                ),
              ],
            ),
          ),
          _isTreeView
              ? JsonViewer(widget.jsonData)
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _getPrettyJson(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  /// Copy JSON to clipboard
  void _copyJson() {
    Clipboard.setData(ClipboardData(text: _getPrettyJson()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('JSON copied to clipboard'),
      ),
    );
  }

  /// Get pretty printed JSON
  String _getPrettyJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(widget.jsonData);
  }
}
