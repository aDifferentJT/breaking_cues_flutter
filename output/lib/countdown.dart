import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_utils/text_size.dart';
import 'package:flutter_utils/widget_modifiers.dart';

class AnalogueCountdownPainter extends CustomPainter {
  final double strokeWidth;
  final Color colour;
  final Duration remaining;

  const AnalogueCountdownPainter({
    required this.strokeWidth,
    required this.colour,
    required this.remaining,
  });

  Paint get _paint => Paint()
    ..color = colour
    ..strokeCap = StrokeCap.round
    ..strokeWidth = strokeWidth
    ..style = PaintingStyle.stroke;

  @override
  void paint(final Canvas canvas, final Size size) {
    final center = size.center(const Offset(0, 0));
    canvas.drawCircle(
      center,
      size.shortestSide / 2 - strokeWidth / 2,
      _paint,
    );

    canvas.drawLine(
      center + Offset.fromDirection(0, size.shortestSide / 2 - strokeWidth),
      center +
          Offset.fromDirection(0, size.shortestSide / 2 - strokeWidth * 2.5),
      _paint,
    );
    for (final angle
        in List.generate(11, (index) => (index + 1) * 2 * pi / 12)) {
      canvas.drawLine(
        center +
            Offset.fromDirection(
              angle,
              size.shortestSide / 2 - strokeWidth,
            ),
        center +
            Offset.fromDirection(
              angle,
              size.shortestSide / 2 - strokeWidth * 1.5,
            ),
        _paint,
      );
    }

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), _paint);
    canvas.drawArc(
      Rect.fromCenter(
        center: center,
        width: size.shortestSide / 3,
        height: size.shortestSide / 3,
      ),
      0,
      remaining.inSeconds / 60 / 60 * 2 * pi,
      true,
      _paint..style = PaintingStyle.fill,
    );
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _paint..blendMode = BlendMode.dstOut,
    );
    canvas.drawLine(
      center,
      center +
          Offset.fromDirection(
            remaining.inSeconds / 60 * 2 * pi,
            size.shortestSide / 2 - strokeWidth * 4,
          ),
      _paint
        ..color = Colors.white
        ..maskFilter = MaskFilter.blur(BlurStyle.solid, strokeWidth / 4)
        ..strokeCap = StrokeCap.butt
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
    canvas.restore();

    canvas.drawLine(
      center,
      center +
          Offset.fromDirection(
            remaining.inSeconds * 2 * pi / 60,
            size.shortestSide / 2 - strokeWidth * 4,
          ),
      _paint
        ..color = Colors.white
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant final CustomPainter oldDelegate) {
    return this != oldDelegate;
  }

  @override
  bool operator ==(final Object other) {
    return other is AnalogueCountdownPainter &&
        strokeWidth == other.strokeWidth &&
        colour == other.colour &&
        remaining == other.remaining;
  }

  @override
  int get hashCode => Object.hash(strokeWidth, colour, remaining);
}

@immutable
class AnalogueCountdown extends StatelessWidget {
  final Duration remaining;
  final double strokeWidth;
  final Color colour;

  const AnalogueCountdown({
    super.key,
    required this.remaining,
    required this.strokeWidth,
    required this.colour,
  });

  @override
  Widget build(final BuildContext context) {
    return CustomPaint(
      painter: AnalogueCountdownPainter(
        strokeWidth: strokeWidth,
        colour: colour,
        remaining: remaining,
      ),
    ).rotated(quarterTurns: -1).constraintsTransform(
          (constraints) => constraints.copyWith(
            minWidth: constraints.maxWidth,
            minHeight: constraints.maxHeight,
          ),
        );
  }
}

@immutable
class DigitalCountdown extends StatelessWidget {
  final Duration remaining;
  final TextStyle style;
  final double digitWidth;

  DigitalCountdown({super.key, required this.remaining, required this.style})
      : digitWidth = '0123456789'
            .runes
            .map((char) => textSize(
                  String.fromCharCode(char),
                  style,
                  double.infinity,
                ).width)
            .max;

  @override
  Widget build(BuildContext context) {
    Iterable<Widget> toWidgets(String x) => x.runes.map(
          (char) => Text(
            String.fromCharCode(char),
            style: style,
          ).centered().sized(width: digitWidth),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...?(remaining.inHours > 0
            ? [
                ...toWidgets('${remaining.inHours}'.padLeft(2, '0')),
                Text(':', style: style),
              ]
            : null),
        ...?(remaining.inMinutes > 0
            ? [
                ...toWidgets('${remaining.inMinutes % 60}'.padLeft(2, '0')),
                Text(':', style: style),
              ]
            : null),
        ...toWidgets('${remaining.inSeconds % 60}'.padLeft(2, '0')),
        ...?(remaining.inMinutes == 0 ? [Text('s', style: style)] : null),
      ],
    );
  }
}
