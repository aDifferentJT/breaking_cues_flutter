import 'dart:math';

import 'package:flutter/material.dart';

import 'package:output/rrect_animation.dart';
import 'package:flutter_utils/widget_modifiers.dart';

randomRRect() {
  final random = Random();
  final width = random.nextInt(1920) + 1;
  final height = random.nextInt(1080) + 1;
  final centerX = random.nextInt(1920 - width) + width / 2;
  final centerY = random.nextInt(1080 - height) + height / 2;
  return RRect.pieces(
    left: centerX - width / 2,
    right: 1920 - centerX - width / 2,
    top: centerY - height / 2,
    bottom: 1080 - centerY - height / 2,
    topLeftRadius: random.nextInt(min(width, height) ~/ 2).toDouble(),
    topRightRadius: random.nextInt(min(width, height) ~/ 2).toDouble(),
    bottomLeftRadius: random.nextInt(min(width, height) ~/ 2).toDouble(),
    bottomRightRadius: random.nextInt(min(width, height) ~/ 2).toDouble(),
  );
}

class RRectAnimationTest extends StatefulWidget {
  const RRectAnimationTest({super.key});

  @override
  createState() => RRectAnimationTestState();
}

class RRectAnimationTestState extends State<RRectAnimationTest>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  var rrectAnimation =
      RRectAnimatable(begin: randomRRect(), end: randomRRect());

  @override
  void initState() {
    super.initState();

    animationController =
        AnimationController(duration: const Duration(seconds: 5), vsync: this)
          ..addListener(() => setState(() {}))
          ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final rrect = rrectAnimation.evaluate(animationController);

    return LayoutBuilder(builder: (context, constraints) {
      return Transform.scale(
        scale: min(
          constraints.maxWidth / 1920,
          constraints.maxHeight / 1080,
        ),
        child: OverflowBox(
          maxWidth: 1920,
          maxHeight: 1080,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.black),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(100),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(rrect.topLeftRadius),
                    topRight: Radius.circular(rrect.topRightRadius),
                    bottomLeft: Radius.circular(rrect.bottomLeftRadius),
                    bottomRight: Radius.circular(rrect.bottomRightRadius),
                  ),
                ),
              ).positioned(
                left: rrect.left,
                right: rrect.right,
                top: rrect.top,
                bottom: rrect.bottom,
              ),
            ],
          ),
        ),
      );
    }).gestureDetector(
      onTap: () => setState(() {
        animationController.stop();
        final current = rrectAnimation.evaluate(animationController);
        rrectAnimation = RRectAnimatable(begin: current, end: randomRRect());
        animationController.reset();
        animationController.forward();
      }),
    );
  }
}

void main() {
  runApp(const RRectAnimationTest());
}
