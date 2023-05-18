import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:core/iterable_utils.dart';
import 'package:core/music.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intersperse/intersperse.dart';

@immutable
class BoundingBox {
  final double north;
  final double south;
  final double west;
  final double east;

  const BoundingBox({
    required this.north,
    required this.south,
    required this.west,
    required this.east,
  });
}

@immutable
class SMuFL {
  final Map<String, dynamic> classes;
  final Map<String, dynamic> glyphnames;
  final Map<String, dynamic> ranges;
  final Map<String, dynamic> bravuraMetadata;
  final Map<String, dynamic> lelandMetadata;

  const SMuFL._byParts({
    required this.classes,
    required this.glyphnames,
    required this.ranges,
    required this.bravuraMetadata,
    required this.lelandMetadata,
  });

  static Future<SMuFL> load() async {
    return SMuFL._byParts(
      classes: jsonDecode(
        await rootBundle.loadString(
          'packages/fonts/smufl/metadata/classes.json',
        ),
      ),
      glyphnames: jsonDecode(
        await rootBundle.loadString(
          'packages/fonts/smufl/metadata/glyphnames.json',
        ),
      ),
      ranges: jsonDecode(
        await rootBundle.loadString(
          'packages/fonts/smufl/metadata/ranges.json',
        ),
      ),
      bravuraMetadata: jsonDecode(
        await rootBundle.loadString(
          'packages/fonts/bravura/redist/bravura_metadata.json',
        ),
      ),
      lelandMetadata: jsonDecode(
        await rootBundle.loadString(
          'packages/fonts/Leland/leland_metadata.json',
        ),
      ),
    );
  }

  String glyph(String name) {
    final data = glyphnames[name];
    if (data == null) {
      return '?';
    }
    final String? codepointString = data['codepoint'];
    if (codepointString == null) {
      return '?';
    }
    final codepoint = int.tryParse(codepointString.substring(2), radix: 16);
    if (codepoint == null) {
      return '?';
    }
    return String.fromCharCode(codepoint);
  }

  BoundingBox boundingBox(String name) {
    final data = lelandMetadata['glyphBBoxes'][name];
    if (data == null) {
      return const BoundingBox(north: 0, south: 0, west: 0, east: 0);
    }
    return BoundingBox(
      north: data['bBoxNE']?[1] ?? 0,
      south: data['bBoxSW']?[1] ?? 0,
      west: data['bBoxSW']?[0] ?? 0,
      east: data['bBoxNE']?[0] ?? 0,
    );
  }

  TextSpan textSpan(
    final Iterable<String> smuflNames, {
    TextStyle style = const TextStyle(),
    bool inline = false,
  }) =>
      TextSpan(
        text: smuflNames.map(glyph).join(),
        style: style.copyWith(
          fontFamily: inline ? 'BravuraText' : 'Leland',
          textBaseline: TextBaseline.alphabetic,
          package: 'fonts',
        ),
      );

  factory SMuFL.of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SMuFLProvider>()!.sMuFL;
}

class _SMuFLProvider extends InheritedWidget {
  final SMuFL sMuFL;

  const _SMuFLProvider({required this.sMuFL, required super.child});

  @override
  bool updateShouldNotify(covariant _SMuFLProvider oldWidget) => false;
}

@immutable
class SMuFLProvider extends StatefulWidget {
  final Widget child;

  const SMuFLProvider({super.key, required this.child});

  @override
  createState() => _SMuFLProviderState();
}

class _SMuFLProviderState extends State<SMuFLProvider> {
  final _sMuFLFuture = SMuFL.load();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sMuFLFuture,
      builder: (context, sMuFL) {
        final data = sMuFL.data;
        if (data != null) {
          return _SMuFLProvider(sMuFL: data, child: widget.child);
        } else {
          return const CupertinoActivityIndicator();
        }
      },
    );
  }
}

class _SMuFLPainter {
  final TextPainter _textPainter;
  final SMuFL smufl;
  final Iterable<String> smuflNames;
  final double staveSpacing;

  _SMuFLPainter({
    required this.smufl,
    required this.smuflNames,
    required Color colour,
    required this.staveSpacing,
  }) : _textPainter = TextPainter(
          text: smufl.textSpan(
            smuflNames,
            style: TextStyle(
              color: colour,
              fontSize: staveSpacing,
            ),
          ),
          textDirection: TextDirection.ltr,
        ) {
    _textPainter.textScaleFactor = 1.0;
    _textPainter.layout();
    _textPainter.textScaleFactor =
        _textPainter.computeLineMetrics().first.height / staveSpacing;
    _textPainter.layout();
  }

  void paint(Canvas canvas, Offset offset) {
    var lineMetrics = _textPainter.computeLineMetrics().first;
    _textPainter.paint(
      canvas,
      offset + Offset(0, -lineMetrics.baseline),
    );
  }

  LineMetrics get metrics => _textPainter.computeLineMetrics().first;

  BoundingBox get boundingBox => smufl.boundingBox(smuflNames.first);
}

@immutable
class GlyphMetrics {
  final double minWidth;
  final double ascent;
  final double descent;
  final double duration;

  const GlyphMetrics({
    required this.minWidth,
    required this.ascent,
    required this.descent,
    required this.duration,
  });
}

abstract class GlyphPainter {
  const GlyphPainter._const();

  GlyphMetrics get metrics;

  void layout({
    required double width,
    required double ascent,
    required double descent,
  });

  void paint(
    Canvas canvas, {
    required Offset offset,
  });

  factory GlyphPainter(
    Glyph glyph, {
    required SMuFL sMuFL,
    required Color colour,
    required double staveSpacing,
    required double textSize,
  }) {
    if (glyph is Clef) {
      return _ClefPainter(
        glyph,
        sMuFL: sMuFL,
        colour: colour,
        staveSpacing: staveSpacing,
      );
    } else if (glyph is Chord) {
      return _ChordPainter(
        glyph,
        sMuFL: sMuFL,
        colour: colour,
        staveSpacing: staveSpacing,
        stemDirectionBias: StemDirection.up,
      );
      // } else if (glyph is Barline) {
      //   return _BarlinePainter(
      //     [_BarlineComponent.thin].toBuiltList(),
      //     context: context,
      //     smufl: smufl,
      //     colour: colour,
      //     staveSpacing: staveSpacing,
      //   );
      // } else if (glyph is EndBarline) {
      //   return _BarlinePainter(
      //     [
      //       _BarlineComponent.thin,
      //       _BarlineComponent.thick,
      //     ].toBuiltList(),
      //     context: context,
      //     smufl: smufl,
      //     colour: colour,
      //     staveSpacing: staveSpacing,
      //   );
      // } else if (glyph is StartRepeat) {
      //   return _BarlinePainter(
      //     [
      //       _BarlineComponent.thick,
      //       _BarlineComponent.thin,
      //       _BarlineComponent.dots,
      //     ].toBuiltList(),
      //     context: context,
      //     smufl: smufl,
      //     colour: colour,
      //     staveSpacing: staveSpacing,
      //   );
      // } else if (glyph is EndRepeat) {
      //   return _BarlinePainter(
      //     [
      //       _BarlineComponent.dots,
      //       _BarlineComponent.thin,
      //       _BarlineComponent.thick,
      //     ].toBuiltList(),
      //     context: context,
      //     smufl: smufl,
      //     colour: colour,
      //     staveSpacing: staveSpacing,
      //   );
      // } else if (glyph is Lyric) {
      //   return _LyricPainter(
      //     glyph,
      //     colour: colour,
      //     staveSpacing: staveSpacing,
      //     textSize: textSize,
      //   );
    } else {
      throw ArgumentError.value(glyph, 'Glyph type not recognised');
    }
  }
}

class _HorizontallySpacedGlyphPainter {
  final GlyphPainter painter;
  bool expanding;

  _HorizontallySpacedGlyphPainter(this.painter)
      : expanding = painter.metrics.duration > 0;

  double width(double widthPerDuration) => expanding
      ? painter.metrics.duration * widthPerDuration
      : painter.metrics.minWidth;

  @override
  String toString() {
    if (expanding) {
      return 'Expanding $painter';
    } else {
      return 'Fixed $painter';
    }
  }
}

@immutable
class _ClefPainter extends GlyphPainter {
  final _SMuFLPainter painter;
  final double yOffset;
  final double staveSpacing;

  _ClefPainter(
    Clef clef, {
    required SMuFL sMuFL,
    required Color colour,
    required this.staveSpacing,
  })  : painter = _SMuFLPainter(
          smufl: sMuFL,
          smuflNames: [
            () {
              if (clef is TrebleClef) {
                return 'gClef';
              } else if (clef is BassClef) {
                return 'fClef';
              } else if (clef is AltoClef) {
                return 'cClef';
              } else if (clef is TenorClef) {
                return 'cClef';
              } else {
                return '';
              }
            }()
          ],
          colour: colour,
          staveSpacing: staveSpacing,
        ),
        yOffset = (staveSpacing *
            () {
              if (clef is TrebleClef) {
                return 3.0;
              } else if (clef is BassClef) {
                return 1.0;
              } else if (clef is AltoClef) {
                return 2.0;
              } else if (clef is TenorClef) {
                return 1.0;
              } else {
                return 0.0;
              }
            }()),
        super._const();

  @override
  get metrics => GlyphMetrics(
        minWidth: painter.metrics.width,
        ascent: painter.boundingBox.north * staveSpacing - yOffset,
        descent: -painter.boundingBox.south * staveSpacing +
            yOffset -
            4 * staveSpacing,
        duration: 0,
      );

  @override
  void layout({
    required double width,
    required double ascent,
    required double descent,
  }) {}

  @override
  void paint(Canvas canvas, {required Offset offset}) {
    painter.paint(canvas, offset + Offset(0, yOffset));
  }
}

enum StemDirection {
  up,
  down;

  @override
  toString() {
    switch (this) {
      case StemDirection.up:
        return 'Up';
      case StemDirection.down:
        return 'Down';
    }
  }
}

@immutable
class _BasicChordPainter extends GlyphPainter {
  final Chord chord;
  final SMuFL sMuFL;
  final _SMuFLPainter noteheadPainter;
  final _SMuFLPainter augmentationDotPainter;
  late final _SMuFLPainter? flagPainter;
  final Color colour;
  final double staveSpacing;
  final bool beamed;

  final StemDirection stemDirection;
  late final double stemStartY;
  late final double stemEndY;

  late final BuiltSet<NotePitch> leftPitches;
  late final BuiltSet<NotePitch> rightPitches;

  _BasicChordPainter(
    this.chord, {
    required this.sMuFL,
    required this.colour,
    required this.staveSpacing,
    required this.stemDirection,
    required this.beamed,
  })  : noteheadPainter = _SMuFLPainter(
          smufl: sMuFL,
          smuflNames: [
            () {
              switch (chord.duration?.fractionOfSemibreve) {
                case 1:
                  return 'noteheadWhole';
                case 2:
                  return 'noteheadHalf';
                default:
                  return 'noteheadBlack';
              }
            }()
          ],
          colour: colour,
          staveSpacing: staveSpacing,
        ),
        augmentationDotPainter = _SMuFLPainter(
          smufl: sMuFL,
          smuflNames: ['augmentationDot'],
          colour: colour,
          staveSpacing: staveSpacing,
        ),
        super._const() {
    flagPainter = (() {
      if (beamed) {
        return null;
      }
      switch (chord.duration?.fractionOfSemibreve) {
        case 8:
          return _SMuFLPainter(
            smufl: sMuFL,
            smuflNames: ['flag8th$stemDirection'],
            colour: colour,
            staveSpacing: staveSpacing,
          );
        case 16:
          return _SMuFLPainter(
            smufl: sMuFL,
            smuflNames: ['flag16th$stemDirection'],
            colour: colour,
            staveSpacing: staveSpacing,
          );
        case 32:
          return _SMuFLPainter(
            smufl: sMuFL,
            smuflNames: ['flag32nd$stemDirection'],
            colour: colour,
            staveSpacing: staveSpacing,
          );
        case 64:
          return _SMuFLPainter(
            smufl: sMuFL,
            smuflNames: ['flag64th$stemDirection'],
            colour: colour,
            staveSpacing: staveSpacing,
          );
        case 128:
          return _SMuFLPainter(
            smufl: sMuFL,
            smuflNames: ['flag128th$stemDirection'],
            colour: colour,
            staveSpacing: staveSpacing,
          );
        case 256:
          return _SMuFLPainter(
            smufl: sMuFL,
            smuflNames: ['flag256th$stemDirection'],
            colour: colour,
            staveSpacing: staveSpacing,
          );
        case 512:
          return _SMuFLPainter(
            smufl: sMuFL,
            smuflNames: ['flag512th$stemDirection'],
            colour: colour,
            staveSpacing: staveSpacing,
          );
        case 1024:
          return _SMuFLPainter(
            smufl: sMuFL,
            smuflNames: ['flag1024th$stemDirection'],
            colour: colour,
            staveSpacing: staveSpacing,
          );
        default:
          return null;
      }
    }());

    final leftPitchesBuilder = SetBuilder<NotePitch>();
    final rightPitchesBuilder = SetBuilder<NotePitch>();

    switch (stemDirection) {
      case StemDirection.down:
        stemStartY = ((chord.pitches
                        .map((pitch) => pitch.distanceDownFromCentre)
                        .minOrNull
                        ?.toDouble() ??
                    0) +
                4) *
            staveSpacing /
            2;
        stemEndY = ((chord.pitches
                            .map((pitch) => pitch.distanceDownFromCentre)
                            .maxOrNull
                            ?.toDouble() ??
                        0) +
                    4) *
                staveSpacing /
                2 +
            3.5 * staveSpacing;

        {
          NotePitch? previousPitch;
          for (final pitch in chord.pitches
              .sortedBy<num>((pitch) => pitch.distanceDownFromCentre)) {
            if (pitch.distanceDownFromCentre - 1 ==
                previousPitch?.distanceDownFromCentre) {
              leftPitchesBuilder.add(pitch);
              previousPitch = null;
            } else {
              rightPitchesBuilder.add(pitch);
              previousPitch = pitch;
            }
          }
        }
        break;
      case StemDirection.up:
        stemStartY = ((chord.pitches
                        .map((pitch) => pitch.distanceDownFromCentre)
                        .maxOrNull
                        ?.toDouble() ??
                    0) +
                4) *
            staveSpacing /
            2;
        stemEndY = ((chord.pitches
                            .map((pitch) => pitch.distanceDownFromCentre)
                            .minOrNull
                            ?.toDouble() ??
                        0) +
                    4) *
                staveSpacing /
                2 -
            3.5 * staveSpacing;

        {
          NotePitch? previousPitch;
          for (final pitch in chord.pitches
              .sortedBy<num>((pitch) => -pitch.distanceDownFromCentre)) {
            if (pitch.distanceDownFromCentre + 1 ==
                previousPitch?.distanceDownFromCentre) {
              rightPitchesBuilder.add(pitch);
              previousPitch = null;
            } else {
              leftPitchesBuilder.add(pitch);
              previousPitch = pitch;
            }
          }
        }
        break;
    }

    leftPitches = leftPitchesBuilder.build();
    rightPitches = rightPitchesBuilder.build();
  }

  @override
  get metrics => GlyphMetrics(
        minWidth: (leftPitches.isEmpty ? 0 : noteheadPainter.metrics.width) +
            max(
              (rightPitches.isEmpty ? 0 : noteheadPainter.metrics.width) +
                  ((chord.duration?.numAugmentationDots ?? 0) * 2 / 3 - 1 / 3) *
                      staveSpacing,
              flagPainter?.metrics.width ?? 0,
            ),
        ascent: max(0, -stemEndY),
        descent: max(0, stemEndY - 4 * staveSpacing),
        duration: 0,
      );

  @override
  void layout({
    required double width,
    required double ascent,
    required double descent,
  }) {}

  double get stemThickness =>
      sMuFL.lelandMetadata['engravingDefaults']['stemThickness'] * staveSpacing;

  Offset get stemOffset {
    switch (stemDirection) {
      case StemDirection.up:
        return Offset(
          sMuFL.lelandMetadata['glyphsWithAnchors']['noteheadBlack']['stemUpSE']
                      [0] *
                  staveSpacing -
              stemThickness / 2,
          -sMuFL.lelandMetadata['glyphsWithAnchors']['noteheadBlack']
                  ['stemUpSE'][1] *
              staveSpacing,
        );
      case StemDirection.down:
        return Offset(
          sMuFL.lelandMetadata['glyphsWithAnchors']['noteheadBlack']
                      ['stemDownNW'][0] *
                  staveSpacing +
              stemThickness / 2,
          -sMuFL.lelandMetadata['glyphsWithAnchors']['noteheadBlack']
                  ['stemDownNW'][1] *
              staveSpacing,
        );
    }
  }

  @override
  void paint(Canvas canvas, {required Offset offset}) {
    if (chord.duration != null && chord.duration!.fractionOfSemibreve >= 2) {
      if (!beamed) {
        canvas.drawLine(
          offset + Offset(0, stemStartY) + stemOffset,
          offset + Offset(stemOffset.dx, stemEndY),
          Paint()
            ..color = colour
            ..strokeWidth = stemThickness,
        );
      }
      flagPainter?.paint(
        canvas,
        offset +
            Offset(
              leftPitches.isEmpty
                  ? 0
                  : noteheadPainter.metrics.width - stemThickness,
              stemEndY,
            ),
      );
    }
    for (final pitch in leftPitches) {
      noteheadPainter.paint(
        canvas,
        offset +
            Offset(
              0,
              (pitch.distanceDownFromCentre + 4) * staveSpacing / 2,
            ),
      );
      for (var i = 0; i < (chord.duration?.numAugmentationDots ?? 0); i += 1) {
        augmentationDotPainter.paint(
          canvas,
          offset +
              Offset(
                (leftPitches.isEmpty ? 0 : noteheadPainter.metrics.width) +
                    (rightPitches.isEmpty ? 0 : noteheadPainter.metrics.width) +
                    (1 / 3 + i * 2 / 3) * staveSpacing,
                ((pitch.distanceDownFromCentre + 3) ~/ 2) * staveSpacing +
                    staveSpacing / 2,
              ),
        );
      }
    }
    for (final pitch in rightPitches) {
      noteheadPainter.paint(
        canvas,
        offset +
            Offset(
              leftPitches.isEmpty
                  ? 0
                  : noteheadPainter.metrics.width - stemThickness / 2,
              (pitch.distanceDownFromCentre + 4) * staveSpacing / 2,
            ),
      );
    }
  }
}

@immutable
class _ChordPainter extends GlyphPainter {
  final _BasicChordPainter painter;

  _ChordPainter(
    final Chord chord, {
    required final SMuFL sMuFL,
    required final Color colour,
    required final double staveSpacing,
    required final StemDirection stemDirectionBias,
  })  : painter = _BasicChordPainter(
          chord,
          sMuFL: sMuFL,
          colour: colour,
          staveSpacing: staveSpacing,
          stemDirection: () {
            final furthestFromCentre = chord.pitches
                .maxBy((pitch) => pitch.distanceDownFromCentre.abs());
            if (furthestFromCentre == null) {
              return stemDirectionBias;
            } else {
              return furthestFromCentre.distanceDownFromCentre.sign < 0
                  ? StemDirection.down
                  : StemDirection.up;
            }
          }(),
          beamed: false,
        ),
        super._const();

  @override
  void layout({
    required double width,
    required double ascent,
    required double descent,
  }) =>
      painter.layout(
        width: width,
        ascent: ascent,
        descent: descent,
      );

  @override
  GlyphMetrics get metrics => painter.metrics;

  @override
  void paint(Canvas canvas, {required Offset offset}) =>
      painter.paint(canvas, offset: offset);
}

@immutable
class _BeamedChordPainter extends GlyphPainter {
  final SMuFL sMuFL;
  final Color colour;
  final double textSize;
  final double staveSpacing;
  late final StemDirection stemDirection;
  late final LaidOutBaseGlyphs<_BasicChordPainter> laidOutBasicChords;
  late final double beamStartHeight;
  late final double beamEndHeight;

  double beamHeight({required final int noteDistanceDownFromCentre}) {
    switch (stemDirection) {
      case StemDirection.up:
        if (noteDistanceDownFromCentre % 2 == 0) {
          return (noteDistanceDownFromCentre - 2.5) * staveSpacing / 2;
        } else {
          return (noteDistanceDownFromCentre - 3) * staveSpacing / 2;
        }
      case StemDirection.down:
        if (noteDistanceDownFromCentre % 2 == 0) {
          return (noteDistanceDownFromCentre + 10.5) * staveSpacing / 2;
        } else {
          return (noteDistanceDownFromCentre + 11) * staveSpacing / 2;
        }
    }
  }

  _BeamedChordPainter(
    final BuiltList<Chord> chords, {
    required this.sMuFL,
    required this.colour,
    required this.textSize,
    required this.staveSpacing,
    required final StemDirection stemDirectionBias,
  }) : super._const() {
    stemDirection = () {
      final furthestFromCentreFirst = chords.first.pitches
          .maxBy((pitch) => pitch.distanceDownFromCentre.abs());
      final furthestFromCentreLast = chords.first.pitches
          .maxBy((pitch) => pitch.distanceDownFromCentre.abs());
      if (furthestFromCentreFirst == null) {
        if (furthestFromCentreLast == null) {
          return stemDirectionBias;
        } else {
          return furthestFromCentreLast.distanceDownFromCentre.sign < 0
              ? StemDirection.down
              : StemDirection.up;
        }
      } else {
        if (furthestFromCentreLast == null) {
          return furthestFromCentreFirst.distanceDownFromCentre.sign < 0
              ? StemDirection.down
              : StemDirection.up;
        } else {
          if (furthestFromCentreFirst.distanceDownFromCentre < 0 &&
              furthestFromCentreLast.distanceDownFromCentre < 0) {
            return StemDirection.down;
          } else if (furthestFromCentreFirst.distanceDownFromCentre > 0 &&
              furthestFromCentreLast.distanceDownFromCentre > 0) {
            return StemDirection.up;
          } else if (furthestFromCentreFirst.distanceDownFromCentre.abs() >
              furthestFromCentreLast.distanceDownFromCentre.abs()) {
            return furthestFromCentreFirst.distanceDownFromCentre < 0
                ? StemDirection.down
                : StemDirection.up;
          } else if (furthestFromCentreFirst.distanceDownFromCentre.abs() <
              furthestFromCentreLast.distanceDownFromCentre.abs()) {
            return furthestFromCentreLast.distanceDownFromCentre < 0
                ? StemDirection.down
                : StemDirection.up;
          } else {
            return stemDirectionBias;
          }
        }
      }
    }();

    beamStartHeight = beamHeight(
      noteDistanceDownFromCentre:
          chords.first.pitches.map((pitch) => pitch.distanceDownFromCentre).min,
    );
    beamEndHeight = beamHeight(
      noteDistanceDownFromCentre:
          chords.last.pitches.map((pitch) => pitch.distanceDownFromCentre).min,
    );

    laidOutBasicChords = LaidOutBaseGlyphs._beamed(
      chords: chords,
      sMuFL: sMuFL,
      colour: colour,
      textSize: textSize,
      staveSpacing: staveSpacing,
      stemDirection: stemDirection,
    );
  }

  @override
  void layout({
    required double width,
    required double ascent,
    required double descent,
  }) {
    for (final glyph in laidOutBasicChords.glyphs) {
      glyph.painter.layout(
        width: width,
        ascent: ascent,
        descent: descent,
      );
    }
  }

  @override
  GlyphMetrics get metrics {
    final metricses = laidOutBasicChords.glyphs
        .map((glyph) => glyph.painter.metrics)
        .toBuiltList();
    return GlyphMetrics(
      minWidth: metricses
          .map((metrics) => metrics.minWidth)
          .intersperse(staveSpacing)
          .sum,
      ascent: [
        ...metricses.map((metrics) => metrics.ascent),
        -beamStartHeight,
        -beamEndHeight,
      ].max,
      descent: [
        ...metricses.map((metrics) => metrics.descent),
        beamStartHeight - 4 * staveSpacing,
        beamEndHeight - 4 * staveSpacing,
      ].max,
      duration: metricses.map((metrics) => metrics.duration).sum,
    );
  }

  double get stemThickness =>
      sMuFL.lelandMetadata['engravingDefaults']['stemThickness'] * staveSpacing;

  @override
  void paint(Canvas canvas, {required Offset offset}) {
    final beamStartX = offset.dx +
        laidOutBasicChords.glyphs.first.xOffset +
        laidOutBasicChords.glyphs.first.painter.stemOffset.dx -
        stemThickness / 2;
    final beamEndX = offset.dx +
        laidOutBasicChords.glyphs.last.xOffset +
        laidOutBasicChords.glyphs.last.painter.stemOffset.dx +
        stemThickness / 2;
    var beamThickness = sMuFL.lelandMetadata['engravingDefaults']
            ['beamThickness'] *
        staveSpacing;
    if (stemDirection == StemDirection.down) {
      beamThickness = -beamThickness;
    }
    canvas.drawPath(
      Path()
        ..moveTo(
          beamStartX,
          offset.dy + beamStartHeight,
        )
        ..lineTo(
          beamEndX,
          offset.dy + beamEndHeight,
        )
        ..lineTo(
          beamEndX,
          offset.dy + beamEndHeight + beamThickness,
        )
        ..lineTo(
          beamStartX,
          offset.dy + beamStartHeight + beamThickness,
        ),
      Paint()..color = colour,
    );
    for (final glyph in laidOutBasicChords.glyphs) {
      canvas.drawLine(
        offset +
            Offset(
              glyph.xOffset,
              (glyph.painter.chord.pitches
                          .map((pitch) => pitch.distanceDownFromCentre)
                          .max +
                      4) *
                  staveSpacing /
                  2,
            ) +
            glyph.painter.stemOffset,
        offset +
            Offset(
              glyph.xOffset + glyph.painter.stemOffset.dx,
              lerpDouble(
                    beamStartHeight,
                    beamEndHeight,
                    glyph.xOffset / (beamEndX - beamStartX),
                  )! +
                  beamThickness / 2,
            ),
        Paint()
          ..color = colour
          ..strokeWidth = stemThickness,
      );
      glyph.painter.paint(canvas, offset: offset + Offset(glyph.xOffset, 0));
    }
  }
}

@immutable
class LaidOutBaseGlyph<GlyphPainterT> {
  final GlyphPainterT painter;
  final double xOffset;

  const LaidOutBaseGlyph({required this.painter, required this.xOffset});
}

@immutable
class LaidOutBaseGlyphs<GlyphPainterT extends GlyphPainter> {
  final BuiltList<LaidOutBaseGlyph<GlyphPainterT>> glyphs;
  final double staveSpacing;
  final double ascent;
  final double descent;
  final double width;

  LaidOutBaseGlyphs({
    required this.glyphs,
    required this.staveSpacing,
    required this.width,
  })  : ascent = glyphs.map((glyph) => glyph.painter.metrics.ascent).max,
        descent = glyphs.map((glyph) => glyph.painter.metrics.descent).max {
    for (final glyph in glyphs) {
      glyph.painter.layout(
        width: glyph.painter.metrics.minWidth,
        ascent: ascent,
        descent: descent,
      );
    }
  }

  static LaidOutBaseGlyphs<GlyphPainter> leftAligned({
    required final BuiltList<Glyph> glyphs,
    required final SMuFL sMuFL,
    required final Color colour,
    required final double textSize,
    required final double staveSpacing,
  }) {
    final glyphClusters = glyphs.splitBetween((first, second) {
      if (first is Chord && second is Chord) {
        return (first.duration?.fractionOfSemibreve ?? 4) < 8 ||
            (second.duration?.fractionOfSemibreve ?? 4) < 8;
      } else {
        return true;
      }
    });

    var xPos = staveSpacing;
    final laidOutGlyphs =
        BuiltList<LaidOutBaseGlyph<GlyphPainter>>.build((laidOutGlyphs) {
      for (final glyphCluster in glyphClusters) {
        final painter = () {
          if (glyphCluster.length == 1) {
            return GlyphPainter(
              glyphCluster.single,
              sMuFL: sMuFL,
              colour: colour,
              staveSpacing: staveSpacing,
              textSize: textSize,
            );
          } else {
            return _BeamedChordPainter(
              glyphCluster.cast<Chord>().toBuiltList(),
              sMuFL: sMuFL,
              colour: colour,
              textSize: textSize,
              staveSpacing: staveSpacing,
              stemDirectionBias: StemDirection.up,
            );
          }
        }();
        laidOutGlyphs.add(LaidOutBaseGlyph(painter: painter, xOffset: xPos));
        xPos += painter.metrics.minWidth + staveSpacing * 2;
      }
    });
    final width = xPos;

    return LaidOutBaseGlyphs(
      glyphs: laidOutGlyphs,
      staveSpacing: staveSpacing,
      width: width,
    );
  }

  static LaidOutBaseGlyphs<_BasicChordPainter> _beamed({
    required final BuiltList<Chord> chords,
    required final SMuFL sMuFL,
    required final Color colour,
    required final double textSize,
    required final double staveSpacing,
    required final StemDirection stemDirection,
  }) {
    var xPos = 0.0;
    final laidOutGlyphs =
        BuiltList<LaidOutBaseGlyph<_BasicChordPainter>>.build((laidOutGlyphs) {
      for (final chord in chords) {
        final painter = () {
          return _BasicChordPainter(
            chord,
            sMuFL: sMuFL,
            colour: colour,
            staveSpacing: staveSpacing,
            stemDirection: stemDirection,
            beamed: true,
          );
        }();
        laidOutGlyphs.add(LaidOutBaseGlyph(painter: painter, xOffset: xPos));
        xPos += painter.metrics.minWidth + staveSpacing;
      }
    });
    final width = xPos;

    return LaidOutBaseGlyphs(
      glyphs: laidOutGlyphs,
      staveSpacing: staveSpacing,
      width: width,
    );
  }
}

@immutable
class _StavePainter extends CustomPainter {
  final LaidOutBaseGlyphs laidOutBaseGlyphs;
  final Color colour;
  final SMuFL smufl;

  const _StavePainter({
    required this.laidOutBaseGlyphs,
    required this.colour,
    required this.smufl,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final laidOutBaseGlyph in laidOutBaseGlyphs.glyphs) {
      laidOutBaseGlyph.painter.paint(
        canvas,
        offset: Offset(laidOutBaseGlyph.xOffset, laidOutBaseGlyphs.ascent),
      );
    }

    for (var i = 0; i < 5; i += 1) {
      final paint = Paint()
        ..color = colour
        ..strokeWidth = laidOutBaseGlyphs.staveSpacing *
            smufl.lelandMetadata['engravingDefaults']['staffLineThickness'];
      canvas.drawLine(
        Offset(
          0,
          laidOutBaseGlyphs.ascent + laidOutBaseGlyphs.staveSpacing * i - 0.5,
        ),
        Offset(
          laidOutBaseGlyphs.width,
          laidOutBaseGlyphs.ascent + laidOutBaseGlyphs.staveSpacing * i - 0.5,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StavePainter oldDelegate) {
    return laidOutBaseGlyphs != oldDelegate.laidOutBaseGlyphs ||
        laidOutBaseGlyphs.staveSpacing !=
            oldDelegate.laidOutBaseGlyphs.staveSpacing;
  }
}

@immutable
class StaveWidget extends StatelessWidget {
  final LaidOutBaseGlyphs laidOutBaseGlyphs;
  final Color colour;

  const StaveWidget({
    required this.laidOutBaseGlyphs,
    super.key,
    required this.colour,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StavePainter(
        laidOutBaseGlyphs: laidOutBaseGlyphs,
        colour: colour,
        smufl: SMuFL.of(context),
      ),
      size: Size(
        laidOutBaseGlyphs.width,
        laidOutBaseGlyphs.ascent +
            laidOutBaseGlyphs.staveSpacing * 4 +
            laidOutBaseGlyphs.descent,
      ),
    );
  }
}
