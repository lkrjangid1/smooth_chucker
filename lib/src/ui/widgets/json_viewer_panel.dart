import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_json_viewer/flutter_json_viewer.dart';

import 'body_search.dart';

/// Widget for displaying JSON data with controls
class JsonViewerPanel extends StatefulWidget {
  /// The JSON data to display
  final dynamic jsonData;

  /// Title of the panel
  final String title;

  /// Matches to highlight in the text view, as returned by [findTextMatches]
  /// on [prettyJson] of the same data
  final List<TextMatch> matches;

  /// Index in [matches] of the currently selected match
  final int currentMatchIndex;

  /// Key attached to the currently selected match, so the parent can scroll
  /// to it
  final GlobalKey? currentMatchKey;

  /// Whether a search is running, in which case the panel stays in text view
  final bool isSearching;

  /// Constructor
  const JsonViewerPanel({
    super.key,
    required this.jsonData,
    required this.title,
    this.matches = const [],
    this.currentMatchIndex = 0,
    this.currentMatchKey,
    this.isSearching = false,
  });

  /// Pretty printed representation of [data]
  static String prettyJson(dynamic data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  @override
  State<JsonViewerPanel> createState() => _JsonViewerPanelState();
}

class _JsonViewerPanelState extends State<JsonViewerPanel> {
  bool _isTreeView = true;

  @override
  Widget build(BuildContext context) {
    // The tree view cannot show highlights, so searching forces the text view.
    final showTreeView = _isTreeView && !widget.isSearching;

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
                        showTreeView ? Icons.code : Icons.account_tree,
                      ),
                      onPressed: widget.isSearching
                          ? null
                          : () {
                              setState(() {
                                _isTreeView = !_isTreeView;
                              });
                            },
                      tooltip: widget.isSearching
                          ? 'Text view is used while searching'
                          : (showTreeView ? 'Show as text' : 'Show as tree'),
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
          showTreeView
              ? JsonViewer(widget.jsonData)
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectionArea(
                    child: HighlightedText(
                      text: _getPrettyJson(),
                      matches: widget.matches,
                      currentMatchIndex: widget.currentMatchIndex,
                      currentMatchKey: widget.currentMatchKey,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                      ),
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
  String _getPrettyJson() => JsonViewerPanel.prettyJson(widget.jsonData);
}
