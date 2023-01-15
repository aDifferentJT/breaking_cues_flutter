import 'package:flutter/animation.dart';

extension AnimationTrigger on AnimationController {
  TickerFuture trigger() {
    if (isAnimating) {
      if (velocity > 0) {
        return reverse();
      } else {
        return forward();
      }
    } else {
      if (value == upperBound) {
        return reverse();
      } else {
        return forward();
      }
    }
  }
}
