import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// [text] with each key of [links] (found inside it) tappable and styled as a link.
class LinkedText extends StatefulWidget {
  const LinkedText({
    super.key,
    required this.text,
    required this.links,
    this.style,
  });

  final String text;
  final Map<String, VoidCallback> links;
  final TextStyle? style;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  List<InlineSpan> _spans(TextStyle linkStyle) {
    final text = widget.text;
    final spans = <InlineSpan>[];
    var start = 0;
    while (start < text.length) {
      final (at, label) = _nextLink(text, start);
      if (label == null) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (at > start) spans.add(TextSpan(text: text.substring(start, at)));
      final recognizer = TapGestureRecognizer()..onTap = widget.links[label];
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(text: label, style: linkStyle, recognizer: recognizer),
      );
      start = at + label.length;
    }
    return spans;
  }

  (int, String?) _nextLink(String text, int from) {
    var first = (text.length, null as String?);
    for (final label in widget.links.keys) {
      final at = text.indexOf(label, from);
      if (at >= 0 && at < first.$1) first = (at, label);
    }
    return first;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(children: _spans(linkStyle)),
      style: widget.style,
    );
  }
}
