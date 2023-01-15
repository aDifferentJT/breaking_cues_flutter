import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:core/iterable_utils.dart';

@immutable
class RRectEnd {
  final double edgeInset;
  final double radius1;
  final double radius2;

  const RRectEnd({
    required this.edgeInset,
    required this.radius1,
    required this.radius2,
  });

  @override
  bool operator ==(Object other) =>
      other is RRectEnd &&
      edgeInset == other.edgeInset &&
      radius1 == other.radius1 &&
      radius2 == other.radius2;

  @override
  int get hashCode => Object.hash(edgeInset, radius1, radius2);
}

@immutable
class RRectEndAnimatable extends Animatable<RRectEnd> {
  final Animatable<double> edgeInset;
  final Animatable<double> radius1;
  final Animatable<double> radius2;

  @override
  transform(double t) => RRectEnd(
        edgeInset: edgeInset.transform(t),
        radius1: radius1.transform(t),
        radius2: radius2.transform(t),
      );

  double get _distance => [edgeInset, radius1, radius2]
      .map((e) => (e.transform(0) - e.transform(1)).abs() + 0.001)
      .max;

  const RRectEndAnimatable._byParts(
      {required this.edgeInset, required this.radius1, required this.radius2});

  RRectEndAnimatable._tween({required RRectEnd begin, required RRectEnd end})
      : edgeInset = Tween(begin: begin.edgeInset, end: end.edgeInset),
        radius1 = Tween(begin: begin.radius1, end: end.radius1),
        radius2 = Tween(begin: begin.radius2, end: end.radius2);

  RRectEndAnimatable._fromItems(Iterable<RRectEndAnimatable> items)
      : edgeInset = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.edgeInset,
                  weight: item._distance,
                ))
            .toList(growable: false)),
        radius1 = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.radius1,
                  weight: item._distance,
                ))
            .toList(growable: false)),
        radius2 = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.radius2,
                  weight: item._distance,
                ))
            .toList(growable: false));

  factory RRectEndAnimatable({
    required RRectEnd begin,
    required RRectEnd end,
    required double crossAxisSize,
  }) {
    if (begin.edgeInset == end.edgeInset) {
      return RRectEndAnimatable._byParts(
        edgeInset: ConstantTween(end.edgeInset),
        radius1: Tween(begin: begin.radius1, end: end.radius1),
        radius2: Tween(begin: begin.radius2, end: end.radius2),
      );
    } else if (begin.edgeInset < end.edgeInset) {
      final radius = min(
        end.edgeInset - begin.edgeInset,
        crossAxisSize / 2,
      );
      final mid1 = RRectEnd(
        edgeInset: begin.edgeInset,
        radius1: radius,
        radius2: radius,
      );
      final mid2 = RRectEnd(
        edgeInset: end.edgeInset - radius,
        radius1: radius,
        radius2: radius,
      );
      return RRectEndAnimatable._fromItems([
        ...?(begin != mid1
            ? [RRectEndAnimatable._tween(begin: begin, end: mid1)]
            : null),
        ...?(mid1 != mid2
            ? [RRectEndAnimatable._tween(begin: mid1, end: mid2)]
            : null),
        ...?(mid2 != end
            ? [RRectEndAnimatable._tween(begin: mid2, end: end)]
            : null),
      ]);
    } else if (begin.edgeInset > end.edgeInset) {
      final radius = min(
        begin.edgeInset - end.edgeInset,
        crossAxisSize / 2,
      );
      final mid1 = RRectEnd(
        edgeInset: begin.edgeInset - radius,
        radius1: radius,
        radius2: radius,
      );
      final mid2 = RRectEnd(
        edgeInset: end.edgeInset,
        radius1: radius,
        radius2: radius,
      );
      return RRectEndAnimatable._fromItems([
        ...?(begin != mid1
            ? [RRectEndAnimatable._tween(begin: begin, end: mid1)]
            : null),
        ...?(mid1 != mid2
            ? [RRectEndAnimatable._tween(begin: mid1, end: mid2)]
            : null),
        ...?(mid2 != end
            ? [RRectEndAnimatable._tween(begin: mid2, end: end)]
            : null),
      ]);
    } else {
      throw 0; // Impossible
    }
  }
}

@immutable
class RRect {
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double topLeftRadius;
  final double topRightRadius;
  final double bottomLeftRadius;
  final double bottomRightRadius;

  double get width => 1920 - left - right;
  double get height => 1080 - top - bottom;

  double get area => width * height;

  double get centerX => (left + 1920 - right) / 2;
  double get centerY => (top + 1080 - bottom) / 2;

  bool get isValid {
    return left + right < 1920 &&
        top + bottom < 1080 &&
        topLeftRadius + topRightRadius < width &&
        bottomLeftRadius + bottomRightRadius < width &&
        topLeftRadius + bottomLeftRadius < height &&
        topRightRadius + bottomRightRadius < height;
  }

  @override
  bool operator ==(Object other) =>
      other is RRect &&
      left == other.left &&
      right == other.right &&
      top == other.top &&
      bottom == other.bottom &&
      topLeftRadius == other.topLeftRadius &&
      topRightRadius == other.topRightRadius &&
      bottomLeftRadius == other.bottomLeftRadius &&
      bottomRightRadius == other.bottomRightRadius;

  @override
  int get hashCode => Object.hash(
        left,
        right,
        top,
        bottom,
        topLeftRadius,
        topRightRadius,
        bottomLeftRadius,
        bottomRightRadius,
      );

  const RRect({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required double radius,
  })  : topLeftRadius = radius,
        topRightRadius = radius,
        bottomLeftRadius = radius,
        bottomRightRadius = radius;

  const RRect.pieces({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.topLeftRadius,
    required this.topRightRadius,
    required this.bottomLeftRadius,
    required this.bottomRightRadius,
  });

  RRect.stadium({
    required double left,
    required double right,
    required double top,
    required double bottom,
  }) : this(
          left: left,
          right: right,
          top: top,
          bottom: bottom,
          radius: min(1920 - left - right, 1080 - top - bottom) / 2,
        );

  factory RRect.intersection(RRect lhs, RRect rhs) {
    final left = max(lhs.left, rhs.left);
    final right = max(lhs.right, rhs.right);
    final top = max(lhs.top, rhs.top);
    final bottom = max(lhs.bottom, rhs.bottom);
    return RRect.pieces(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      topLeftRadius: max(
          lhs.top == top && lhs.left == left ? lhs.topLeftRadius : 0,
          rhs.top == top && rhs.left == left ? rhs.topLeftRadius : 0),
      topRightRadius: max(
          lhs.top == top && lhs.right == right ? lhs.topRightRadius : 0,
          rhs.top == top && rhs.right == right ? rhs.topRightRadius : 0),
      bottomLeftRadius: max(
          lhs.bottom == bottom && lhs.left == left ? lhs.bottomLeftRadius : 0,
          rhs.bottom == bottom && rhs.left == left ? rhs.bottomLeftRadius : 0),
      bottomRightRadius: max(
          lhs.bottom == bottom && lhs.right == right
              ? lhs.bottomRightRadius
              : 0,
          rhs.bottom == bottom && rhs.right == right
              ? rhs.bottomRightRadius
              : 0),
    );
  }
}

@immutable
class RRectAnimatable extends Animatable<RRect> {
  final Animatable<double> left;
  final Animatable<double> right;
  final Animatable<double> top;
  final Animatable<double> bottom;
  final Animatable<double> topLeftRadius;
  final Animatable<double> topRightRadius;
  final Animatable<double> bottomLeftRadius;
  final Animatable<double> bottomRightRadius;

  @override
  transform(double t) => RRect.pieces(
        left: left.transform(t),
        right: right.transform(t),
        top: top.transform(t),
        bottom: bottom.transform(t),
        topLeftRadius: topLeftRadius.transform(t),
        topRightRadius: topRightRadius.transform(t),
        bottomLeftRadius: bottomLeftRadius.transform(t),
        bottomRightRadius: bottomRightRadius.transform(t),
      );

  RRectAnimatable.constant(RRect rrect)
      : left = ConstantTween(rrect.left),
        right = ConstantTween(rrect.right),
        top = ConstantTween(rrect.top),
        bottom = ConstantTween(rrect.bottom),
        topLeftRadius = ConstantTween(rrect.topLeftRadius),
        topRightRadius = ConstantTween(rrect.topRightRadius),
        bottomLeftRadius = ConstantTween(rrect.bottomLeftRadius),
        bottomRightRadius = ConstantTween(rrect.bottomRightRadius);

  RRectAnimatable._horizontal({
    required RRectEndAnimatable left,
    required RRectEndAnimatable right,
    required double top,
    required double bottom,
  })  : left = left.edgeInset,
        right = right.edgeInset,
        top = ConstantTween(top),
        bottom = ConstantTween(bottom),
        topLeftRadius = left.radius1,
        topRightRadius = right.radius1,
        bottomLeftRadius = left.radius2,
        bottomRightRadius = right.radius2;

  RRectAnimatable._vertical({
    required RRectEndAnimatable top,
    required RRectEndAnimatable bottom,
    required double left,
    required double right,
  })  : left = ConstantTween(left),
        right = ConstantTween(right),
        top = top.edgeInset,
        bottom = bottom.edgeInset,
        topLeftRadius = top.radius1,
        topRightRadius = top.radius2,
        bottomLeftRadius = bottom.radius1,
        bottomRightRadius = bottom.radius2;

  factory RRectAnimatable({required RRect begin, required RRect end}) {
    if (begin == end) {
      return RRectAnimatable.constant(end);
    } else if (begin.left == end.left &&
        begin.right == end.right &&
        begin.top == end.top &&
        begin.bottom == end.bottom) {
      return RRectAnimatable.tween(begin: begin, end: end);
    } else if (begin.left == end.left && begin.right == end.right) {
      return RRectAnimatable._vertical(
        top: RRectEndAnimatable(
          begin: RRectEnd(
            edgeInset: begin.top,
            radius1: begin.topLeftRadius,
            radius2: begin.topRightRadius,
          ),
          end: RRectEnd(
            edgeInset: end.top,
            radius1: end.topLeftRadius,
            radius2: end.topRightRadius,
          ),
          crossAxisSize: end.width,
        ),
        bottom: RRectEndAnimatable(
          begin: RRectEnd(
            edgeInset: begin.bottom,
            radius1: begin.bottomLeftRadius,
            radius2: begin.bottomRightRadius,
          ),
          end: RRectEnd(
            edgeInset: end.bottom,
            radius1: end.bottomLeftRadius,
            radius2: end.bottomRightRadius,
          ),
          crossAxisSize: end.width,
        ),
        left: end.left,
        right: end.right,
      );
    } else if (begin.top == end.top && begin.bottom == end.bottom) {
      return RRectAnimatable._horizontal(
        left: RRectEndAnimatable(
          begin: RRectEnd(
            edgeInset: begin.left,
            radius1: begin.topLeftRadius,
            radius2: begin.bottomLeftRadius,
          ),
          end: RRectEnd(
            edgeInset: end.left,
            radius1: end.topLeftRadius,
            radius2: end.bottomLeftRadius,
          ),
          crossAxisSize: end.height,
        ),
        right: RRectEndAnimatable(
          begin: RRectEnd(
            edgeInset: begin.right,
            radius1: begin.topRightRadius,
            radius2: begin.bottomRightRadius,
          ),
          end: RRectEnd(
            edgeInset: end.right,
            radius1: end.topRightRadius,
            radius2: end.bottomRightRadius,
          ),
          crossAxisSize: end.height,
        ),
        top: end.top,
        bottom: end.bottom,
      );
    } else {
      final mid = [
        RRect.stadium(
          left: begin.left,
          right: begin.right,
          top: end.top,
          bottom: end.bottom,
        ),
        RRect.stadium(
          left: end.left,
          right: end.right,
          top: begin.top,
          bottom: begin.bottom,
        ),
      ].minBy((rrect) => rrect.area)!;
      return RRectAnimatable._fromItems([
        RRectAnimatable(begin: begin, end: mid),
        RRectAnimatable(begin: mid, end: end),
      ]);
    }
  }

  RRectAnimatable.tween({
    required RRect begin,
    required RRect end,
  })  : left = Tween(begin: begin.left, end: end.left),
        right = Tween(begin: begin.right, end: end.right),
        top = Tween(begin: begin.top, end: end.top),
        bottom = Tween(begin: begin.bottom, end: end.bottom),
        topLeftRadius =
            Tween(begin: begin.topLeftRadius, end: end.topLeftRadius),
        topRightRadius =
            Tween(begin: begin.topRightRadius, end: end.topRightRadius),
        bottomLeftRadius =
            Tween(begin: begin.bottomLeftRadius, end: end.bottomLeftRadius),
        bottomRightRadius =
            Tween(begin: begin.bottomRightRadius, end: end.bottomRightRadius);

  double get _distance => [
        left,
        right,
        top,
        bottom,
        topLeftRadius,
        topRightRadius,
        bottomLeftRadius,
        bottomRightRadius,
      ].map((e) => (e.transform(0) - e.transform(1)).abs()).max;

  RRectAnimatable._fromItems(Iterable<RRectAnimatable> items)
      : left = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.left,
                  weight: item._distance,
                ))
            .toList(growable: false)),
        right = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.right,
                  weight: item._distance,
                ))
            .toList(growable: false)),
        top = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.top,
                  weight: item._distance,
                ))
            .toList(growable: false)),
        bottom = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.bottom,
                  weight: item._distance,
                ))
            .toList(growable: false)),
        topLeftRadius = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.topLeftRadius,
                  weight: item._distance,
                ))
            .toList(growable: false)),
        topRightRadius = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.topRightRadius,
                  weight: item._distance,
                ))
            .toList(growable: false)),
        bottomLeftRadius = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.bottomLeftRadius,
                  weight: item._distance,
                ))
            .toList(growable: false)),
        bottomRightRadius = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.bottomRightRadius,
                  weight: item._distance,
                ))
            .toList(growable: false));
}
