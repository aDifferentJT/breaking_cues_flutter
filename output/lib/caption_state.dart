import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_utils/widget_modifiers.dart';
import 'package:intersperse/intersperse.dart';
import 'package:petitparser/petitparser.dart';

import 'package:core/deck.dart';
import 'package:core/parser.dart';
import 'package:flutter_utils/text_size.dart';
import 'package:output/display_settings_flutter.dart';

import 'colour_to_flutter.dart';
import 'rrect_animation.dart';

final formatTextParser = () {
  final parser = undefined<List<InlineSpan>>();
  parser.set([
    pattern('^*/').map((text) => TextSpan(text: text)),
    parser
        .map(
          (span) => TextSpan(
            children: span,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        )
        .skip(before: char('*'), after: char('*')),
    parser
        .map(
          (span) => TextSpan(
            children: span,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        )
        .skip(before: char('/'), after: char('/')),
  ].toChoiceParser().star());
  return parser.resolve().end();
}();

List<InlineSpan> formatText(String text) {
  final result = formatTextParser.parse(text);
  if (result.isFailure) {
    print(result.message);
  }
  return result.valueOr(() => [TextSpan(text: text)]);
}

@immutable
class CountdownState {
  final CountdownChunk slide;
  final double opacity;
  final DisplaySettings displaySettings;

  const CountdownState({
    required this.slide,
    required this.opacity,
    required this.displaySettings,
  });

  bool get isStopped =>
      slide.countdownTo.difference(DateTime.now()) < slide.stopAt;

  Duration get remaining => slide.countdownTo.difference(DateTime.now());

  CountdownState withOpacity(final double opacity) => CountdownState(
        slide: slide,
        opacity: opacity,
        displaySettings: displaySettings,
      );
}

@immutable
class CaptionState {
  final RRect rrect;
  final Color backgroundColour;
  final EdgeInsetsGeometry edgeInsets;
  final BuiltMap<Widget, AlignmentGeometry> overlayLayers;
  final CountdownState? countdown;

  const CaptionState.pieces({
    required this.rrect,
    required this.backgroundColour,
    required this.edgeInsets,
    required this.overlayLayers,
    required this.countdown,
  });

  factory CaptionState({
    required DeckIndex deckIndex,
    required DisplaySettings displaySettings,
    required String name,
  }) {
    final slide = deckIndex.slide;
    if (slide is CountdownChunk) {
      return CaptionState.pieces(
        rrect: const RRect(
          left: 960,
          right: 960,
          top: 540,
          bottom: 540,
          radius: 0,
        ),
        backgroundColour: displaySettings.backgroundColour.flutter,
        edgeInsets: const EdgeInsets.all(0),
        overlayLayers: BuiltMap(),
        countdown: CountdownState(
          slide: slide,
          opacity: 1,
          displaySettings: displaySettings,
        ),
      );
    } else {
      final rrect = () {
        switch (displaySettings.style) {
          case Style.none:
            return const RRect(
              left: 960,
              right: 960,
              top: 540,
              bottom: 540,
              radius: 0,
            );
          case Style.leftQuarter:
            return const RRect(
              left: 0,
              right: 1440,
              top: 0,
              bottom: 0,
              radius: 0,
            );
          case Style.leftThird:
            return const RRect(
              left: 100,
              right: 1280,
              top: 100,
              bottom: 100,
              radius: 25,
            );
          case Style.leftHalf:
            return const RRect(
              left: 100,
              right: 960,
              top: 100,
              bottom: 100,
              radius: 25,
            );
          case Style.leftTwoThirds:
            return const RRect(
              left: 0,
              right: 640,
              top: 0,
              bottom: 0,
              radius: 0,
            );
          case Style.rightQuarter:
            return const RRect(
              left: 1440,
              right: 0,
              top: 0,
              bottom: 0,
              radius: 0,
            );
          case Style.rightThird:
            return const RRect(
              left: 1280,
              right: 100,
              top: 100,
              bottom: 100,
              radius: 25,
            );
          case Style.rightHalf:
            return const RRect(
              left: 960,
              right: 100,
              top: 100,
              bottom: 100,
              radius: 25,
            );
          case Style.rightTwoThirds:
            return const RRect(
              left: 640,
              right: 0,
              top: 0,
              bottom: 0,
              radius: 0,
            );
          case Style.topLines:
            if (slide is TitleChunk) {
              final textHeight = textSize(
                    TextSpan(
                      children: formatText(slide.title),
                      style: displaySettings.titleStyle,
                    ),
                    1670,
                  ).height *
                  2;

              return RRect.stadium(
                left: 100,
                right: 100,
                top: 100,
                bottom: 980 - textHeight,
              );
            } else if (slide is BodySlide) {
              final textHeight = slide.minorChunks
                  .map((minorChunk) => textSize(
                        TextSpan(
                          children: formatText('$minorChunk\n'),
                          style: displaySettings.bodyStyle,
                        ),
                        1670,
                      ).height)
                  .max;

              return RRect(
                left: 100,
                right: 100,
                top: 100,
                bottom: 980 - textHeight,
                radius: 25,
              );
            } else if (slide is MusicSlide) {
              final textHeight = 200.0;

              return RRect(
                left: 100,
                right: 100,
                top: 100,
                bottom: 980 - textHeight,
                radius: 25,
              );
            } else {
              throw ArgumentError.value(slide, 'Slide type not recognised');
            }
          case Style.bottomLines:
            if (slide is TitleChunk) {
              final textHeight = textSize(
                    TextSpan(
                      children: formatText(slide.title),
                      style: displaySettings.titleStyle,
                    ),
                    1670,
                  ).height *
                  2;

              return RRect.stadium(
                left: 100,
                right: 100,
                top: 980 - textHeight,
                bottom: 100,
              );
            } else if (slide is BodySlide) {
              final textHeight = slide.minorChunks
                  .map((minorChunk) => textSize(
                        TextSpan(
                          children: formatText('$minorChunk\n'),
                          style: displaySettings.bodyStyle,
                        ),
                        1670,
                      ).height)
                  .max;

              return RRect(
                left: 100,
                right: 100,
                top: 980 - textHeight,
                bottom: 100,
                radius: 25,
              );
            } else if (slide is MusicSlide) {
              final textHeight = 200.0;
              return RRect(
                left: 100,
                right: 100,
                top: 980 - textHeight,
                bottom: 100,
                radius: 25,
              );
            } else {
              throw ArgumentError.value(slide, 'Slide type not recognised');
            }
          case Style.bottomParagraphs:
            if (slide is TitleChunk) {
              final textHeight = textSize(
                    TextSpan(
                      children: formatText(slide.title),
                      style: displaySettings.titleStyle,
                    ),
                    1670,
                  ).height *
                  2;

              return RRect.stadium(
                left: 100,
                right: 100,
                top: 980 - textHeight,
                bottom: 100,
              );
            } else if (slide is BodySlide) {
              final textHeight = slide.minorChunks
                  .map((minorChunk) => textSize(
                        TextSpan(
                          children: formatText('$minorChunk\n'),
                          style: displaySettings.bodyStyle,
                        ),
                        (1720 / slide.minorChunks.length) - 50,
                      ).height)
                  .max;

              return RRect(
                left: 100,
                right: 100,
                top: 980 - textHeight,
                bottom: 100,
                radius: 25,
              );
            } else if (slide is MusicSlide) {
              final textHeight = 200.0;
              return RRect(
                left: 100,
                right: 100,
                top: 980 - textHeight,
                bottom: 100,
                radius: 25,
              );
            } else {
              throw ArgumentError.value(slide, 'Slide type not recognised');
            }
          case Style.fullScreen:
            return const RRect(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              radius: 0,
            );
        }
      }();
      final backgroundColour = displaySettings.backgroundColour;
      final edgeInsets = () {
        switch (displaySettings.style) {
          case Style.none:
            return const EdgeInsets.only();

          case Style.leftQuarter:
          case Style.leftThird:
          case Style.leftHalf:
          case Style.rightQuarter:
          case Style.rightThird:
          case Style.rightHalf:
          case Style.topLines:
          case Style.bottomLines:
          case Style.bottomParagraphs:
            if (rrect.height > rrect.width) {
              return EdgeInsets.only(
                top: max(rrect.topLeftRadius, rrect.topRightRadius),
                bottom: max(rrect.bottomLeftRadius, rrect.bottomRightRadius),
                left: 25,
                right: 25,
              );
            } else {
              return EdgeInsets.only(
                left: max(rrect.topLeftRadius, rrect.bottomLeftRadius),
                right: max(rrect.topRightRadius, rrect.bottomRightRadius),
                top: 25,
                bottom: 25,
              );
            }

          case Style.leftTwoThirds:
          case Style.rightTwoThirds:
          case Style.fullScreen:
            return const EdgeInsets.all(100);
        }
      }();
      final overlayLayers = () {
        switch (displaySettings.style) {
          case Style.none:
            return BuiltMap<Widget, AlignmentGeometry>();

          case Style.leftQuarter:
          case Style.leftThird:
          case Style.leftHalf:
          case Style.rightQuarter:
          case Style.rightThird:
          case Style.rightHalf:
          case Style.topLines:
          case Style.bottomLines:
            if (slide is TitleChunk) {
              return BuiltMap.of({
                RichText(
                  text: TextSpan(
                    children: formatText(slide.title),
                    style: displaySettings.titleStyle,
                  ),
                  textAlign: TextAlign.start,
                ): AlignmentDirectional.centerStart,
                RichText(
                  text: TextSpan(
                    children: formatText(slide.subtitle),
                    style: displaySettings.subtitleStyle,
                  ),
                  textAlign: TextAlign.end,
                ): AlignmentDirectional.bottomEnd,
              });
            } else if (slide is BodySlide) {
              return BuiltMap.of({
                RichText(
                  text: TextSpan(
                    children: formatText(slide.minorChunk),
                    style: displaySettings.bodyStyle,
                  ),
                  textAlign: TextAlign.center,
                ): AlignmentDirectional.center,
              });
            } else if (slide is MusicSlide) {
              return BuiltMap<Widget, AlignmentGeometry>();
              // final laidOutBaseGlyphs = LaidOutBaseGlyphs.leftAligned(
              //   glyphs: slide.minorChunk.baseGlyphs,
              //   sMuFL: SMuFL.of(context),
              //   colour: displaySettings.textColour.flutter,
              //   textSize: displaySettings.bodySize,
              // );
              // return BuiltMap.of({
              //   StaveWidget(
              //     laidOutBaseGlyphs: laidOutBaseGlyphs,
              //     colour: displaySettings.textColour.flutter,
              //     textSize: displaySettings.bodySize,
              //   ).constraintsTransform(
              //     (constraints) => constraints.copyWith(
              //       minWidth: constraints.maxWidth,
              //       minHeight: constraints.maxHeight,
              //     ),
              //   ): AlignmentDirectional.center,
              // });
            } else {
              throw ArgumentError.value(slide, 'Slide type not recognised');
            }

          case Style.leftTwoThirds:
          case Style.rightTwoThirds:
          case Style.fullScreen:
            if (slide is TitleChunk) {
              return BuiltMap.of({
                RichText(
                  text: TextSpan(
                    children: formatText(slide.title),
                    style: displaySettings.titleStyle,
                  ),
                  textAlign: TextAlign.center,
                ): AlignmentDirectional.topCenter,
                RichText(
                  text: TextSpan(
                    children: formatText(slide.subtitle),
                    style: displaySettings.subtitleStyle,
                  ),
                  textAlign: TextAlign.end,
                ): AlignmentDirectional.bottomEnd,
              });
            } else if (slide is BodySlide) {
              return BuiltMap.of({
                RichText(
                  text: TextSpan(
                    children: formatText(slide.minorChunks.join('\n')),
                    style: displaySettings.bodyStyle,
                  ),
                  textAlign: TextAlign.center,
                ): AlignmentDirectional.topCenter,
              });
            } else if (slide is MusicSlide) {
              return BuiltMap<Widget, AlignmentGeometry>();
              // return BuiltMap.of({
              //   StaveWidget(
              //     slide.minorChunk,
              //     colour: displaySettings.textColour.flutter,
              //     textSize: displaySettings.bodySize,
              //   ).constraintsTransform(
              //     (constraints) => constraints.copyWith(
              //       minWidth: constraints.maxWidth,
              //       minHeight: constraints.maxHeight,
              //     ),
              //   ): AlignmentDirectional.center,
              // });
            } else {
              throw ArgumentError.value(slide, 'Slide type not recognised');
            }

          case Style.bottomParagraphs:
            if (slide is TitleChunk) {
              return BuiltMap.of({
                RichText(
                  text: TextSpan(
                    children: formatText(slide.title),
                    style: displaySettings.titleStyle,
                  ),
                  textAlign: TextAlign.start,
                ): AlignmentDirectional.centerStart,
                RichText(
                  text: TextSpan(
                    children: formatText(slide.subtitle),
                    style: displaySettings.subtitleStyle,
                  ),
                  textAlign: TextAlign.end,
                ): AlignmentDirectional.bottomEnd,
              });
            } else if (slide is BodySlide) {
              return BuiltMap.of({
                Row(
                  children: slide.minorChunks
                      .map(
                        (minorChunk) => RichText(
                          text: TextSpan(
                            children: formatText(minorChunk),
                            style: displaySettings.bodyStyle,
                          ),
                          textAlign: TextAlign.center,
                        ).expanded(),
                      )
                      .intersperse(const SizedBox(width: 50))
                      .toList(),
                ): AlignmentDirectional.center,
              });
            } else if (slide is MusicSlide) {
              return BuiltMap<Widget, AlignmentGeometry>();
              // final laidOutBaseGlyphs = LaidOutBaseGlyphs.leftAligned(
              //   glyphs: slide.minorChunk.baseGlyphs,
              //   sMuFL: SMuFL.of(context),
              //   colour: displaySettings.textColour.flutter,
              //   textSize: displaySettings.bodySize,
              // );
              // return BuiltMap.of({
              //   StaveWidget(
              //     laidOutBaseGlyphs: laidOutBaseGlyphs,
              //     colour: displaySettings.textColour.flutter,
              //     textSize: displaySettings.bodySize,
              //   ).constraintsTransform(
              //     (constraints) => constraints.copyWith(
              //       minWidth: constraints.maxWidth,
              //       minHeight: constraints.maxHeight,
              //     ),
              //   ): AlignmentDirectional.center,
              // });
            } else {
              throw ArgumentError.value(slide, 'Slide type not recognised');
            }
        }
      }();
      return CaptionState.pieces(
        rrect: rrect,
        backgroundColour: backgroundColour.flutter,
        edgeInsets: edgeInsets,
        overlayLayers: overlayLayers,
        countdown: null,
      );
    }
  }

  CaptionState.closed({double centerX = 960, double centerY = 540})
      : rrect = RRect(
          left: centerX,
          right: 1920 - centerX,
          top: centerY,
          bottom: 1080 - centerY,
          radius: 0,
        ),
        backgroundColour = Colors.transparent,
        edgeInsets = EdgeInsets.zero,
        overlayLayers = BuiltMap(),
        countdown = null;

  CaptionState.circle({
    required Style style,
    required CaptionState nextState,
  })  : rrect = RRect.pieces(
          left: nextState.rrect.left,
          right:
              1920 - nextState.rrect.left - nextState.rrect.topLeftRadius * 2,
          top: nextState.rrect.top,
          bottom:
              1080 - nextState.rrect.top - nextState.rrect.topLeftRadius * 2,
          topLeftRadius: nextState.rrect.topLeftRadius,
          topRightRadius: nextState.rrect.topLeftRadius,
          bottomLeftRadius: nextState.rrect.topLeftRadius,
          bottomRightRadius: nextState.rrect.topLeftRadius,
        ),
        backgroundColour = nextState.backgroundColour,
        edgeInsets = EdgeInsets.zero,
        overlayLayers = BuiltMap(),
        countdown = null;

  CaptionState withOverlayLayers(
          final BuiltMap<Widget, AlignmentGeometry> overlayLayers) =>
      CaptionState.pieces(
          rrect: rrect,
          backgroundColour: backgroundColour,
          edgeInsets: edgeInsets,
          overlayLayers: overlayLayers,
          countdown: countdown);

  CaptionState mapOverlayLayers(final Widget Function(Widget) f) =>
      withOverlayLayers(
        overlayLayers.map(
          (widget, alignment) => MapEntry(f(widget), alignment),
        ),
      );
}
