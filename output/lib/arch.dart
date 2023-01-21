import 'package:flutter/material.dart';

@immutable
class _ArchPainter extends CustomPainter {
  final Color colour;

  const _ArchPainter({required this.colour});

  Paint get _paint => Paint()
    ..color = colour
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.clipRect(rect);
    canvas.saveLayer(rect, Paint());
    canvas.drawPaint(_paint);
    canvas.saveLayer(
      rect,
      Paint()..blendMode = BlendMode.dstOut,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        -size.height / 4,
        size.height / 2,
        size.width + size.height / 2,
        size.height,
      ),
      Paint()
        ..color = Colors.black
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height / 8),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArchPainter oldDelegate) =>
      colour != oldDelegate.colour;
}

@immutable
class Arch extends StatelessWidget {
  final Color colour;

  const Arch({super.key, required this.colour});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ArchPainter(colour: colour));
}
