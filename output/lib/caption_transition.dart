import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';

import 'package:core/deck.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'caption_state.dart';
import 'rrect_animation.dart';

@immutable
class StepAnimatable<T> extends Animatable<T> {
  final T begin;
  final T end;

  const StepAnimatable({required this.begin, required this.end});

  @override
  T transform(double t) => t < 0.5 ? begin : end;
}

@immutable
class MapTween<K, V> extends Animatable<BuiltMap<K, V>> {
  final BuiltMap<K, Animatable<V>> _tweens;

  MapTween({
    required BuiltMap<K, V> begin,
    required BuiltMap<K, V> end,
    final Animatable<V> Function({required V begin, required V end})?
        tweenConstructor,
  }) : _tweens = BuiltMap.of(Map.fromIterable(
          [begin, end].expand((item) => item.keys).toBuiltSet(),
          value: (key) {
            final beginValue = (begin[key] ?? end[key]) as V;
            final endValue = (end[key] ?? begin[key]) as V;
            if (tweenConstructor == null) {
              return Tween(begin: beginValue, end: endValue);
            } else {
              return tweenConstructor(begin: beginValue, end: endValue);
            }
          },
        ));

  @override
  BuiltMap<K, V> transform(double t) =>
      _tweens.map((key, value) => MapEntry(key, value.transform(t)));
}

@immutable
class CountdownTween extends Animatable<CountdownState> {
  final StepAnimatable<CountdownSlide> slide;
  final Tween<double> opacity;
  final StepAnimatable<DisplaySettings> displaySettings;

  CountdownTween({
    required CountdownState begin,
    required CountdownState end,
  })  : slide = StepAnimatable(begin: begin.slide, end: end.slide),
        opacity = Tween(begin: begin.opacity, end: end.opacity),
        displaySettings = StepAnimatable(
          begin: begin.displaySettings,
          end: end.displaySettings,
        );

  @override
  CountdownState transform(double t) => CountdownState(
        slide: slide.transform(t),
        opacity: opacity.transform(t),
        displaySettings: displaySettings.transform(t),
      );
}

@immutable
class OptionalCountdownTween extends Animatable<CountdownState?> {
  final CountdownTween? _tween;
  final bool _beginNull;
  final bool _endNull;

  OptionalCountdownTween({
    required CountdownState? begin,
    required CountdownState? end,
  })  : _tween = begin == null && end == null
            ? null
            : CountdownTween(
                begin: begin ?? end!.withOpacity(0),
                end: end ?? begin!.withOpacity(0),
              ),
        _beginNull = begin == null,
        _endNull = end == null;

  @override
  CountdownState? transform(double t) {
    if ((_beginNull && t == 0) || (_endNull && t == 1)) {
      return null;
    } else {
      return _tween?.transform(t);
    }
  }
}

@immutable
class CaptionTransition extends Animatable<CaptionState> {
  final Duration duration;
  final Animatable<RRect> rrect;
  final Animatable<Color?> backgroundColour;
  final Animatable<EdgeInsetsGeometry> edgeInsets;
  final Animatable<BuiltMap<Widget, AlignmentGeometry?>> overlayLayers;
  final Animatable<CountdownState?> countdown;

  CaptionTransition.constant(
    CaptionState value, {
    this.duration = Duration.zero,
  })  : rrect = ConstantTween(value.rrect),
        backgroundColour = ConstantTween(value.backgroundColour),
        edgeInsets = ConstantTween(value.edgeInsets),
        overlayLayers = ConstantTween(value.overlayLayers),
        countdown = ConstantTween(value.countdown);

  CaptionTransition._tween({
    required this.duration,
    required CaptionState begin,
    required CaptionState end,
  })  : rrect = RRectAnimatable(begin: begin.rrect, end: end.rrect),
        backgroundColour = ColorTween(
            begin: begin.backgroundColour, end: end.backgroundColour),
        edgeInsets = EdgeInsetsGeometryTween(
            begin: begin.edgeInsets, end: end.edgeInsets),
        overlayLayers = MapTween(
          begin: begin.overlayLayers,
          end: end.overlayLayers,
          tweenConstructor: ({required begin, required end}) =>
              AlignmentGeometryTween(begin: begin, end: end),
        ),
        countdown = OptionalCountdownTween(
          begin: begin.countdown,
          end: end.countdown,
        );

  CaptionTransition._tweenDirect({
    required this.duration,
    required CaptionState begin,
    required CaptionState end,
  })  : rrect = RRectAnimatable.tween(begin: begin.rrect, end: end.rrect),
        backgroundColour = ColorTween(
            begin: begin.backgroundColour, end: end.backgroundColour),
        edgeInsets = EdgeInsetsGeometryTween(
            begin: begin.edgeInsets, end: end.edgeInsets),
        overlayLayers = MapTween(
          begin: begin.overlayLayers,
          end: end.overlayLayers,
          tweenConstructor: ({required begin, required end}) =>
              AlignmentGeometryTween(begin: begin, end: end),
        ),
        countdown = OptionalCountdownTween(
          begin: begin.countdown,
          end: end.countdown,
        );

  CaptionTransition.fromItems(Iterable<CaptionTransition> items)
      : duration =
            items.fold(Duration.zero, (acc, item) => acc + item.duration),
        rrect = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.rrect,
                  weight: item.duration.inMicroseconds.toDouble(),
                ))
            .toList(growable: false)),
        backgroundColour = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.backgroundColour,
                  weight: item.duration.inMicroseconds.toDouble(),
                ))
            .toList(growable: false)),
        edgeInsets = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.edgeInsets,
                  weight: item.duration.inMicroseconds.toDouble(),
                ))
            .toList(growable: false)),
        overlayLayers = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.overlayLayers,
                  weight: item.duration.inMicroseconds.toDouble(),
                ))
            .toList(growable: false)),
        countdown = TweenSequence(items
            .map((item) => TweenSequenceItem(
                  tween: item.countdown,
                  weight: item.duration.inMicroseconds.toDouble(),
                ))
            .toList(growable: false));

  CaptionTransition.close(CaptionState previousState)
      : this.fromItems([
          CaptionTransition._tween(
            duration: const Duration(milliseconds: 100),
            begin: previousState,
            end: previousState.withOverlayLayers(
              previousState.overlayLayers
                  .map((key, value) => MapEntry(key.opacity(0), value)),
            ),
          ),
          CaptionTransition._tweenDirect(
            duration: const Duration(milliseconds: 100),
            begin: previousState.withOverlayLayers(BuiltMap()),
            end: CaptionState.closed(
              centerX: previousState.rrect.centerX,
              centerY: previousState.rrect.centerY,
            ),
          ),
        ]);

  factory CaptionTransition.show({
    required CaptionState previousState,
    required bool quiet,
    required DeckIndex deckIndex,
    required BuiltMap<String, DisplaySettings> defaultSettings,
    required String name,
  }) {
    final defaultSettings_ =
        defaultSettings[name] ?? const DisplaySettings.default_();
    final displaySettings =
        deckIndex.deck.displaySettings[name]?.withDefaults(defaultSettings_) ??
            defaultSettings_;

    final nextState = CaptionState(
      deckIndex: deckIndex,
      displaySettings: displaySettings,
      name: name,
    );

    appear() {
      final midState = CaptionState.circle(
        style: displaySettings.style,
        nextState: nextState,
      );
      return CaptionTransition.fromItems([
        CaptionTransition._tweenDirect(
          duration: const Duration(milliseconds: 250),
          begin: CaptionState.closed(
            centerX: midState.rrect.centerX,
            centerY: midState.rrect.centerY,
          ),
          end: midState,
        ),
        CaptionTransition._tween(
          duration: const Duration(milliseconds: 250),
          begin: midState,
          end: nextState.withOverlayLayers(BuiltMap()),
        ),
        CaptionTransition._tween(
          duration: const Duration(milliseconds: 250),
          begin: nextState.mapOverlayLayers((widget) => widget.opacity(0)),
          end: nextState,
        ),
      ]);
    }

    if (previousState.rrect.area < 1.0) {
      return appear();
    } else if (quiet) {
      if (previousState.rrect == nextState.rrect) {
        return CaptionTransition.constant(nextState);
      } else {
        return CaptionTransition.fromItems([
          CaptionTransition._tween(
            duration: const Duration(milliseconds: 100),
            begin: previousState,
            end: previousState.mapOverlayLayers((widget) => widget.opacity(0)),
          ),
          CaptionTransition._tween(
            duration: const Duration(milliseconds: 100),
            begin: previousState.withOverlayLayers(BuiltMap()),
            end: nextState.withOverlayLayers(BuiltMap()),
          ),
          CaptionTransition._tween(
            duration: const Duration(milliseconds: 100),
            begin: nextState.mapOverlayLayers((widget) => widget.opacity(0)),
            end: nextState,
          ),
        ]);
      }
    } else {
      return CaptionTransition.fromItems([
        CaptionTransition.close(previousState),
        appear(),
      ]);
    }
  }

  @override
  CaptionState transform(double t) => CaptionState.pieces(
        rrect: rrect.transform(t),
        backgroundColour: backgroundColour.transform(t)!,
        edgeInsets: edgeInsets.transform(t),
        overlayLayers: overlayLayers.transform(t).map(
              (widget, alignmentGeometry) =>
                  MapEntry(widget, alignmentGeometry!),
            ),
        countdown: countdown.transform(t),
      );
}
