import 'package:flutter/widgets.dart';

Size textSize(String text, TextStyle style, double width) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: null,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout(minWidth: 0, maxWidth: width);
  return textPainter.size;
}
