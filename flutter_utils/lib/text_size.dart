import 'package:flutter/widgets.dart';

Size textSize(TextSpan text, double width) {
  final TextPainter textPainter = TextPainter(
    text: text,
    maxLines: null,
    textDirection: TextDirection.ltr,
  );
  textPainter.layout(minWidth: 0, maxWidth: width);
  return textPainter.size;
}
