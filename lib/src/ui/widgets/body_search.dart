import 'package:flutter/material.dart';

/// A single occurrence of a search query inside a body of text
class TextMatch {
  /// Index of the first character of the match
  final int start;

  /// Index just past the last character of the match
  final int end;

  /// Constructor
  const TextMatch(this.start, this.end);
}

/// Find every case-insensitive occurrence of [query] inside [text]
List<TextMatch> findTextMatches(String text, String query) {
  if (text.isEmpty || query.isEmpty) {
    return const [];
  }

  final haystack = text.toLowerCase();
  final needle = query.toLowerCase();
  final matches = <TextMatch>[];

  var index = haystack.indexOf(needle);
  while (index != -1) {
    matches.add(TextMatch(index, index + needle.length));
    index = haystack.indexOf(needle, index + needle.length);
  }

  return matches;
}

/// Background of every match that is not the currently selected one
const _matchColor = Color(0x8AFFEB3B);

/// Background of the currently selected match
const _currentMatchColor = Color(0xFFFF9800);

/// Text that renders [matches] with a highlight, marking [currentMatchIndex]
/// with a stronger color
class HighlightedText extends StatelessWidget {
  /// The full text to render
  final String text;

  /// Matches to highlight, as returned by [findTextMatches]
  final List<TextMatch> matches;

  /// Index in [matches] of the currently selected match
  final int currentMatchIndex;

  /// Key attached to the currently selected match, so callers can scroll to it
  /// with [Scrollable.ensureVisible]
  final GlobalKey? currentMatchKey;

  /// Style applied to the text
  final TextStyle? style;

  /// Constructor
  const HighlightedText({
    super.key,
    required this.text,
    this.matches = const [],
    this.currentMatchIndex = 0,
    this.currentMatchKey,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Text(text, style: style);
    }

    final matchStyle = (style ?? const TextStyle()).copyWith(
      color: Colors.black,
    );
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }

      final matchText = text.substring(match.start, match.end);
      final isCurrent = i == currentMatchIndex;

      if (isCurrent) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              key: currentMatchKey,
              color: _currentMatchColor,
              child: Text(matchText, style: matchStyle),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: matchText,
            style: matchStyle.copyWith(backgroundColor: _matchColor),
          ),
        );
      }

      cursor = match.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(TextSpan(children: spans), style: style);
  }
}

/// Search bar used to look for text inside a request or response body
class BodySearchBar extends StatelessWidget {
  /// Controller of the search field
  final TextEditingController controller;

  /// Focus node of the search field
  final FocusNode? focusNode;

  /// Number of matches for the current query
  final int matchCount;

  /// Index of the currently selected match
  final int currentMatchIndex;

  /// Called when the query changes
  final ValueChanged<String> onChanged;

  /// Called when the previous match is requested
  final VoidCallback onPrevious;

  /// Called when the next match is requested
  final VoidCallback onNext;

  /// Called when the search bar is dismissed
  final VoidCallback onClose;

  /// Hint shown in the search field
  final String hintText;

  /// Constructor
  const BodySearchBar({
    super.key,
    required this.controller,
    required this.matchCount,
    required this.currentMatchIndex,
    required this.onChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
    this.focusNode,
    this.hintText = 'Search in body',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasQuery = controller.text.isNotEmpty;
    final hasMatches = matchCount > 0;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: (_) => onNext(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hintText,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ),
            if (hasQuery)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  hasMatches ? '${currentMatchIndex + 1}/$matchCount' : '0/0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasMatches
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              tooltip: 'Previous match',
              onPressed: hasMatches ? onPrevious : null,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              tooltip: 'Next match',
              onPressed: hasMatches ? onNext : null,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close search',
              onPressed: onClose,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
