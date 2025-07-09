import 'package:flutter/material.dart';

/// Widget untuk menampilkan text dengan formatting markdown sederhana
class RichFormattedText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final Color? linkColor;

  const RichFormattedText({
    super.key,
    required this.text,
    this.baseStyle,
    this.linkColor,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      _parseText(context),
      style: baseStyle,
    );
  }

  TextSpan _parseText(BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*([^*]+)\*\*|\*([^*]+)\*|_([^_]+)_|~~([^~]+)~~');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      // Process the matched formatting
      String matchedText = '';
      TextStyle? style = baseStyle;

      if (match.group(1) != null) {
        // Bold text **text**
        matchedText = match.group(1)!;
        style = baseStyle?.copyWith(fontWeight: FontWeight.bold) ??
            const TextStyle(fontWeight: FontWeight.bold);
      } else if (match.group(2) != null) {
        // Italic text *text*
        matchedText = match.group(2)!;
        style = baseStyle?.copyWith(fontStyle: FontStyle.italic) ??
            const TextStyle(fontStyle: FontStyle.italic);
      } else if (match.group(3) != null) {
        // Italic text _text_
        matchedText = match.group(3)!;
        style = baseStyle?.copyWith(fontStyle: FontStyle.italic) ??
            const TextStyle(fontStyle: FontStyle.italic);
      } else if (match.group(4) != null) {
        // Strikethrough text ~~text~~
        matchedText = match.group(4)!;
        style = baseStyle?.copyWith(decoration: TextDecoration.lineThrough) ??
            const TextStyle(decoration: TextDecoration.lineThrough);
      }

      spans.add(TextSpan(
        text: matchedText,
        style: style,
      ));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans);
  }
}
