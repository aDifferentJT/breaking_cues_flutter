import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:core/music.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

double _yOffsetOfPitch({
  required BasePitch basePitch,
  required int octave,
  required _MusicContext context,
}) =>
    context.clefOffset + basePitch.index / 2 + (octave - 4) * 3.5;

class _MusicContext {
  double clefOffset = 0;
  KeySignature keySignature = const KeySignature.sharps(0);
  Map<double, Accidental> accidentalAtYOffset = {};

  _MusicContext();
}

@immutable
class _BoundingBox {
  final double north;
  final double south;
  final double west;
  final double east;

  const _BoundingBox({
    required this.north,
    required this.south,
    required this.west,
    required this.east,
  });
}

@immutable
class _SMuFL {
  final Map<String, dynamic> classes;
  final Map<String, dynamic> glyphnames;
  final Map<String, dynamic> ranges;
  final Map<String, dynamic> bravuraMetadata;
  final Map<String, dynamic> lelandMetadata;

  const _SMuFL({
    required this.classes,
    required this.glyphnames,
    required this.ranges,
    required this.bravuraMetadata,
    required this.lelandMetadata,
  });

  static Future<_SMuFL> load() async {
    return _SMuFL(
      classes: jsonDecode(
        await rootBundle.loadString(
          'packages/output/fonts/smufl/metadata/classes.json',
        ),
      ),
      glyphnames: jsonDecode(
        await rootBundle.loadString(
          'packages/output/fonts/smufl/metadata/glyphnames.json',
        ),
      ),
      ranges: jsonDecode(
        await rootBundle.loadString(
          'packages/output/fonts/smufl/metadata/ranges.json',
        ),
      ),
      bravuraMetadata: jsonDecode(
        await rootBundle.loadString(
          'packages/output/fonts/bravura/redist/bravura_metadata.json',
        ),
      ),
      lelandMetadata: jsonDecode(
        await rootBundle.loadString(
          'packages/output/fonts/Leland/leland_metadata.json',
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

  _BoundingBox boundingBox(String name) {
    final data = lelandMetadata['glyphBBoxes'][name];
    if (data == null) {
      return const _BoundingBox(north: 0, south: 0, west: 0, east: 0);
    }
    return _BoundingBox(
      north: data['bBoxNE']?[1] ?? 0,
      south: data['bBoxSW']?[1] ?? 0,
      west: data['bBoxSW']?[0] ?? 0,
      east: data['bBoxNE']?[0] ?? 0,
    );
  }
}

class _SMuFLPainter {
  final TextPainter _textPainter;
  final _SMuFL smufl;
  final Iterable<String> smuflNames;
  final double staveSpacing;

  _SMuFLPainter({
    required this.smufl,
    required this.smuflNames,
    required Color colour,
    required this.staveSpacing,
  }) : _textPainter = TextPainter(
          text: TextSpan(
            text: smuflNames.map(smufl.glyph).join(),
            style: TextStyle(
              color: colour,
              fontSize: staveSpacing,
              fontFamily: 'Leland',
              textBaseline: TextBaseline.alphabetic,
              package: 'output',
            ),
          ),
          textDirection: TextDirection.ltr,
        );

  void layout() {
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

  _BoundingBox get boundingBox => smufl.boundingBox(smuflNames.first);
}

@immutable
class _GlyphMetrics {
  final double minWidth;
  final double ascent;
  final double descent;
  final double duration;

  const _GlyphMetrics({
    required this.minWidth,
    required this.ascent,
    required this.descent,
    required this.duration,
  });
}

abstract class _GlyphPainter {
  const _GlyphPainter._const();

  _GlyphMetrics get metrics;

  void layout({
    required double width,
    required double ascent,
    required double descent,
  });

  void paint(
    Canvas canvas, {
    required Offset offset,
  });

  factory _GlyphPainter(
    Glyph glyph, {
    required _MusicContext context,
    required _SMuFL smufl,
    required Color colour,
    required double staveSpacing,
    required double textSize,
  }) {
    if (glyph is HorizontalGroup) {
      return _HorizontalGroupPainter(
        glyph,
        context: context,
        smufl: smufl,
        colour: colour,
        staveSpacing: staveSpacing,
        textSize: textSize,
      );
    } else if (glyph is VerticalGroup) {
      return _VerticalGroupPainter(
        glyph,
        context: context,
        smufl: smufl,
        colour: colour,
        staveSpacing: staveSpacing,
        textSize: textSize,
      );
    } else if (glyph is Clef) {
      return _ClefPainter(
        glyph,
        context: context,
        smufl: smufl,
        colour: colour,
        staveSpacing: staveSpacing,
      );
    } else if (glyph is KeySignature) {
      return _KeySignaturePainter(
        glyph,
        context: context,
        smufl: smufl,
        colour: colour,
        staveSpacing: staveSpacing,
      );
    } else if (glyph is TimeSignature) {
      return _TimeSignaturePainter(
        glyph,
        context: context,
        smufl: smufl,
        colour: colour,
        staveSpacing: staveSpacing,
      );
    } else if (glyph is Note) {
      return _NotePainter(
        glyph,
        context: context,
        smufl: smufl,
        colour: colour,
        staveSpacing: staveSpacing,
      );
    } else if (glyph is Barline) {
      return _BarlinePainter(
        [_BarlineComponent.thin].toBuiltList(),
        context: context,
        smufl: smufl,
        colour: colour,
        staveSpacing: staveSpacing,
      );
    } else if (glyph is EndBarline) {
      return _BarlinePainter(
        [
          _BarlineComponent.thin,
          _BarlineComponent.thick,
        ].toBuiltList(),
        context: context,
        smufl: smufl,
        colour: colour,
        staveSpacing: staveSpacing,
      );
    } else if (glyph is StartRepeat) {
      return _BarlinePainter(
        [
          _BarlineComponent.thick,
          _BarlineComponent.thin,
          _BarlineComponent.dots,
        ].toBuiltList(),
        context: context,
        smufl: smufl,
        colour: colour,
        staveSpacing: staveSpacing,
      );
    } else if (glyph is EndRepeat) {
      return _BarlinePainter(
        [
          _BarlineComponent.dots,
          _BarlineComponent.thin,
          _BarlineComponent.thick,
        ].toBuiltList(),
        context: context,
        smufl: smufl,
        colour: colour,
        staveSpacing: staveSpacing,
      );
    } else if (glyph is Lyric) {
      return _LyricPainter(
        glyph,
        colour: colour,
        staveSpacing: staveSpacing,
        textSize: textSize,
      );
    } else {
      throw ArgumentError.value(glyph, 'Glyph type not recognised');
    }
  }
}

class _HorizontallySpacedGlyphPainter {
  final _GlyphPainter painter;
  bool expanding = true;

  _HorizontallySpacedGlyphPainter(this.painter);

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

class _HorizontalGroupPainter extends _GlyphPainter {
  final BuiltList<_HorizontallySpacedGlyphPainter> painters;
  late double widthPerDuration;

  double get width =>
      painters.map((painter) => painter.width(widthPerDuration)).sum;

  _HorizontalGroupPainter(
    HorizontalGroup group, {
    required _MusicContext context,
    required _SMuFL smufl,
    required Color colour,
    required double staveSpacing,
    required double textSize,
  })  : painters = group.glyphs
            .map(
              (glyph) => _HorizontallySpacedGlyphPainter(
                _GlyphPainter(
                  glyph,
                  context: context,
                  smufl: smufl,
                  colour: colour,
                  staveSpacing: staveSpacing,
                  textSize: textSize,
                ),
              ),
            )
            .toBuiltList(),
        super._const();

  @override
  _GlyphMetrics get metrics {
    final metricses =
        painters.map((painter) => painter.painter.metrics).toBuiltList();
    return _GlyphMetrics(
      minWidth: metricses.map((metrics) => metrics.minWidth).sum,
      ascent: metricses.map((metrics) => metrics.ascent).maxOrNull ?? 0,
      descent: metricses.map((metrics) => metrics.descent).maxOrNull ?? 0,
      duration: metricses.map((metrics) => metrics.duration).sum,
    );
  }

  @override
  void layout({
    required final double width,
    required final double ascent,
    required final double descent,
  }) {
    for (final painter in painters) {
      painter.expanding = true;
    }

    expandingPainters() => painters.where((painter) => painter.expanding);
    fixedPainters() => painters.whereNot((painter) => painter.expanding);

    calculateWidthPerDuration() =>
        (width -
            fixedPainters()
                .map((painter) => painter.painter.metrics.minWidth)
                .sum) /
        expandingPainters()
            .map((painter) => painter.painter.metrics.duration)
            .sum;

    widthPerDuration = calculateWidthPerDuration();

    calculateBadPainters() => expandingPainters().where((painter) =>
        painter.painter.metrics.duration * widthPerDuration <
        painter.painter.metrics.minWidth);

    var badPainters = calculateBadPainters();

    while (badPainters.isNotEmpty) {
      for (final painter in badPainters) {
        painter.expanding = false;
      }
      widthPerDuration = calculateWidthPerDuration();
      badPainters = calculateBadPainters();
    }

    widthPerDuration /= painters.map((painter) {
          var metrics = painter.painter.metrics;
          final minWidth = metrics.minWidth;
          if (metrics.duration > 0 && minWidth > 0) {
            return painter.width(widthPerDuration) / minWidth;
          } else {
            return double.infinity;
          }
        }).minOrNull ??
        1;

    for (final painter in painters) {
      var width = painter.width(widthPerDuration);
      painter.painter.layout(
        width: width,
        ascent: ascent,
        descent: descent,
      );
    }
  }

  @override
  void paint(final Canvas canvas, {required final Offset offset}) {
    var xOffset = 0.0;
    for (final painter in painters) {
      var width = painter.width(widthPerDuration);
      painter.painter.paint(canvas, offset: offset + Offset(xOffset, 0));
      xOffset += width;
    }
  }
}

@immutable
class _VerticalGroupPainter extends _GlyphPainter {
  final BuiltList<_GlyphPainter> _painters;

  _VerticalGroupPainter(
    VerticalGroup group, {
    required _MusicContext context,
    required _SMuFL smufl,
    required Color colour,
    required double staveSpacing,
    required double textSize,
  })  : _painters = group.glyphs
            .map((glyph) => _GlyphPainter(
                  glyph,
                  context: context,
                  smufl: smufl,
                  colour: colour,
                  staveSpacing: staveSpacing,
                  textSize: textSize,
                ))
            .toBuiltList(),
        super._const();

  @override
  _GlyphMetrics get metrics {
    final metricses = _painters.map((painter) => painter.metrics).toBuiltList();
    return _GlyphMetrics(
      minWidth: metricses.map((metrics) => metrics.minWidth).maxOrNull ?? 0,
      ascent: metricses.map((metrics) => metrics.ascent).maxOrNull ?? 0,
      descent: metricses.map((metrics) => metrics.descent).maxOrNull ?? 0,
      duration: metricses.map((metrics) => metrics.duration).maxOrNull ?? 0,
    );
  }

  @override
  void layout({
    required double width,
    required double ascent,
    required double descent,
  }) {
    for (final painter in _painters) {
      painter.layout(
        width: width,
        ascent: ascent,
        descent: descent,
      );
    }
  }

  @override
  void paint(Canvas canvas, {required Offset offset}) {
    for (final painter in _painters) {
      painter.paint(canvas, offset: offset);
    }
  }
}

@immutable
class _ClefPainter extends _GlyphPainter {
  final _SMuFLPainter painter;
  final double yOffset;
  final double staveSpacing;

  _ClefPainter(
    Clef clef, {
    required _MusicContext context,
    required _SMuFL smufl,
    required Color colour,
    required this.staveSpacing,
  })  : painter = _SMuFLPainter(
          smufl: smufl,
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
        )..layout(),
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
        super._const() {
    if (clef is TrebleClef) {
      context.clefOffset = 0;
    } else if (clef is BassClef) {
      context.clefOffset = 6;
    } else if (clef is AltoClef) {
      context.clefOffset = 3;
    } else if (clef is TenorClef) {
      context.clefOffset = 4;
    }
    context.accidentalAtYOffset = {};
  }

  @override
  get metrics => _GlyphMetrics(
        minWidth: painter.metrics.width + 2 * staveSpacing,
        ascent: painter.boundingBox.north * staveSpacing - yOffset,
        descent: 0,
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
    painter.paint(canvas, offset + Offset(staveSpacing, yOffset));
  }
}

@immutable
class _KeySignaturePainter extends _GlyphPainter {
  final _SMuFLPainter painter;
  final BuiltList<Offset> offsets;
  final double staveSpacing;

  const _KeySignaturePainter._init({
    required this.painter,
    required this.offsets,
    required this.staveSpacing,
  }) : super._const();

  static Iterable<Offset> _buildOffsets(
    Iterable<BasePitch> basePitches, {
    required bool isSharp,
    required _MusicContext context,
    required double staveSpacing,
    required _SMuFLPainter painter,
  }) sync* {
    final metrics = painter.metrics;

    // TODO cleffOffset is now 1 bigger than when this was tested
    final octave = 4 - (context.clefOffset / 3.5 - 0.5).round();

    var xOffset = 0.0;
    for (final basePitch in basePitches) {
      final int octaveCorrection;
      switch (basePitch) {
        case BasePitch.A:
        case BasePitch.B:
          octaveCorrection = -1;
          break;
        case BasePitch.F:
        case BasePitch.G:
          if (context.clefOffset == 4) {
            octaveCorrection = -1;
          } else {
            octaveCorrection = 0;
          }
          break;
        default:
          octaveCorrection = 0;
          break;
      }

      yield Offset(
        xOffset,
        5 * staveSpacing -
            _yOffsetOfPitch(
                  basePitch: basePitch,
                  octave: octave + octaveCorrection,
                  context: context,
                ) *
                staveSpacing,
      );

      xOffset += metrics.width;
    }
  }

  factory _KeySignaturePainter(
    KeySignature keySignature, {
    required _MusicContext context,
    required _SMuFL smufl,
    required Color colour,
    required double staveSpacing,
  }) {
    final painter = _SMuFLPainter(
      smufl: smufl,
      smuflNames: [keySignature.isSharp ? 'accidentalSharp' : 'accidentalFlat'],
      colour: colour,
      staveSpacing: staveSpacing,
    )..layout();

    final offsets = _buildOffsets(
      keySignature.isSharp ? keySignature.sharps : keySignature.flats,
      isSharp: keySignature.isSharp,
      context: context,
      staveSpacing: staveSpacing,
      painter: painter,
    ).toBuiltList();

    context.keySignature = keySignature;
    context.accidentalAtYOffset = {};

    return _KeySignaturePainter._init(
      painter: painter,
      offsets: offsets,
      staveSpacing: staveSpacing,
    );
  }

  @override
  _GlyphMetrics get metrics {
    final accidentalMetrics = painter.metrics;
    return _GlyphMetrics(
      minWidth: offsets
              .map((offset) => offset.dx + accidentalMetrics.width)
              .maxOrNull ??
          0,
      ascent: offsets
              .map((offset) => accidentalMetrics.ascent - offset.dy)
              .maxOrNull ??
          0,
      descent: offsets
              .map((offset) =>
                  accidentalMetrics.descent + offset.dy - 4 * staveSpacing)
              .maxOrNull ??
          0,
      duration: 0,
    );
  }

  @override
  void layout({
    required double width,
    required double ascent,
    required double descent,
  }) {}

  @override
  void paint(Canvas canvas, {required Offset offset}) {
    for (final accidentalOffset in offsets) {
      painter.paint(canvas, offset + accidentalOffset);
    }
  }
}

class _TimeSignaturePainter extends _GlyphPainter {
  final _SMuFLPainter upperPainter;
  final _SMuFLPainter lowerPainter;
  final double staveSpacing;
  late double width;

  _TimeSignaturePainter(
    TimeSignature timeSignature, {
    required _MusicContext context,
    required _SMuFL smufl,
    required Color colour,
    required this.staveSpacing,
  })  : upperPainter = _SMuFLPainter(
          smufl: smufl,
          smuflNames: timeSignature.upper.toString().runes.map(
                (rune) => 'timeSig${String.fromCharCode(rune)}',
              ),
          colour: colour,
          staveSpacing: staveSpacing,
        )..layout(),
        lowerPainter = _SMuFLPainter(
          smufl: smufl,
          smuflNames: timeSignature.lower.toString().runes.map(
                (rune) => 'timeSig${String.fromCharCode(rune)}',
              ),
          colour: colour,
          staveSpacing: staveSpacing,
        )..layout(),
        super._const();

  @override
  _GlyphMetrics get metrics {
    final upperMetrics = upperPainter.metrics;
    final lowerMetrics = lowerPainter.metrics;

    return _GlyphMetrics(
      minWidth: max(upperMetrics.width, lowerMetrics.width) + 2 * staveSpacing,
      ascent: (upperPainter.boundingBox.north - 1) * staveSpacing,
      descent: (lowerPainter.boundingBox.south - 1) * staveSpacing,
      duration: 0,
    );
  }

  @override
  void layout({
    required double width,
    required double ascent,
    required double descent,
  }) {
    this.width = width;
  }

  @override
  void paint(Canvas canvas, {required Offset offset}) {
    upperPainter.paint(
      canvas,
      offset +
          Offset(
            (width - upperPainter.metrics.width) / 2,
            1 * staveSpacing,
          ),
    );
    lowerPainter.paint(
      canvas,
      offset +
          Offset(
            (width - lowerPainter.metrics.width) / 2,
            3 * staveSpacing,
          ),
    );
  }
}

@immutable
class _NotePainter extends _GlyphPainter {
  final Note note;
  final double yOffset;

  final _SMuFLPainter? accidentalPainter;
  final Offset accidentalOffset;
  final _SMuFLPainter noteheadPainter;
  final Offset noteheadOffset;
  final double? stemWidth;
  final Offset? stemStart;
  final Offset? stemEnd;
  final _SMuFLPainter? flagPainter;
  final _SMuFLPainter augmentationDotPainter;

  final _SMuFL smufl;
  final Color colour;
  final double staveSpacing;

  const _NotePainter._init({
    required this.note,
    required this.yOffset,
    required this.accidentalPainter,
    required this.accidentalOffset,
    required this.noteheadPainter,
    required this.noteheadOffset,
    required this.stemWidth,
    required this.stemStart,
    required this.stemEnd,
    required this.flagPainter,
    required this.augmentationDotPainter,
    required this.smufl,
    required this.colour,
    required this.staveSpacing,
  }) : super._const();

  factory _NotePainter(
    final Note note, {
    required final _MusicContext context,
    required final _SMuFL smufl,
    required final Color colour,
    required final double staveSpacing,
  }) {
    final yOffset = _yOffsetOfPitch(
      basePitch: note.pitch.basePitch,
      octave: note.pitch.octave,
      context: context,
    );

    final Accidental? accidental;
    if (context.accidentalAtYOffset[yOffset] == note.pitch.accidental) {
      // This accidental matches an earlier one in the same bar
      accidental = null;
    } else if (context.accidentalAtYOffset[yOffset] != null) {
      // This accidental does not match an earlier one in the same bar
      accidental = note.pitch.accidental;
    } else {
      // There is no earlier accidental in the same bar
      switch (note.pitch.accidental) {
        case Accidental.natural:
          if (context.keySignature.sharps.contains(note.pitch.basePitch) ||
              context.keySignature.flats.contains(note.pitch.basePitch)) {
            accidental = note.pitch.accidental;
          } else {
            accidental = null;
          }
          break;
        case Accidental.sharp:
          if (context.keySignature.sharps.contains(note.pitch.basePitch)) {
            accidental = null;
          } else {
            accidental = note.pitch.accidental;
          }
          break;
        case Accidental.flat:
          if (context.keySignature.flats.contains(note.pitch.basePitch)) {
            accidental = null;
          } else {
            accidental = note.pitch.accidental;
          }
          break;
      }
    }

    if (accidental != null) {
      context.accidentalAtYOffset[yOffset] = accidental;
    }

    final _SMuFLPainter? accidentalPainter;
    switch (accidental) {
      case Accidental.natural:
        accidentalPainter = _SMuFLPainter(
          smufl: smufl,
          smuflNames: ['accidentalNatural'],
          colour: colour,
          staveSpacing: staveSpacing,
        )..layout();
        break;
      case Accidental.sharp:
        accidentalPainter = _SMuFLPainter(
          smufl: smufl,
          smuflNames: ['accidentalSharp'],
          colour: colour,
          staveSpacing: staveSpacing,
        )..layout();
        break;
      case Accidental.flat:
        accidentalPainter = _SMuFLPainter(
          smufl: smufl,
          smuflNames: ['accidentalFlat'],
          colour: colour,
          staveSpacing: staveSpacing,
        )..layout();
        break;
      case null:
        accidentalPainter = null;
    }

    final Offset accidentalOffset = Offset(0, (5 - yOffset) * staveSpacing);

    final _SMuFLPainter noteheadPainter;
    switch (note.duration.fractionOfSemibreve) {
      case 1:
        noteheadPainter = _SMuFLPainter(
          smufl: smufl,
          smuflNames: ['noteheadWhole'],
          colour: colour,
          staveSpacing: staveSpacing,
        )..layout();
        break;
      case 2:
        noteheadPainter = _SMuFLPainter(
          smufl: smufl,
          smuflNames: ['noteheadHalf'],
          colour: colour,
          staveSpacing: staveSpacing,
        )..layout();
        break;
      default:
        noteheadPainter = _SMuFLPainter(
          smufl: smufl,
          smuflNames: ['noteheadBlack'],
          colour: colour,
          staveSpacing: staveSpacing,
        )..layout();
        break;
    }

    final Offset noteheadOffset = Offset(
      accidentalPainter != null
          ? accidentalPainter.metrics.width + 0.25 * staveSpacing
          : 0,
      (5 - yOffset) * staveSpacing,
    );

    final double? stemWidth;
    final Offset? stemStart;
    final Offset? stemEnd;
    if (note.duration.fractionOfSemibreve >= 2) {
      stemWidth = smufl.lelandMetadata['engravingDefaults']['stemThickness'] *
          staveSpacing;
      stemStart = noteheadOffset +
          Offset(
            noteheadPainter.metrics.width - stemWidth! / 2,
            0,
          );
      stemEnd = noteheadOffset +
          Offset(
            noteheadPainter.metrics.width - stemWidth / 2,
            (yOffset > 3 ? 3.5 : -3.5) * staveSpacing,
          );
    } else {
      stemWidth = null;
      stemStart = null;
      stemEnd = null;
    }

    final direction = yOffset > 3 ? 'Down' : 'Up';

    final _SMuFLPainter? flagPainter;
    if (note.duration.fractionOfSemibreve >= 8) {
      flagPainter = _SMuFLPainter(
        smufl: smufl,
        smuflNames: ['flag${note.duration.fractionOfSemibreve}th$direction'],
        colour: colour,
        staveSpacing: staveSpacing,
      )..layout();
    } else {
      flagPainter = null;
    }

    final augmentationDotPainter = _SMuFLPainter(
      smufl: smufl,
      smuflNames: ['augmentationDot'],
      colour: colour,
      staveSpacing: staveSpacing,
    )..layout();

    return _NotePainter._init(
      note: note,
      yOffset: yOffset,
      accidentalPainter: accidentalPainter,
      accidentalOffset: accidentalOffset,
      noteheadPainter: noteheadPainter,
      noteheadOffset: noteheadOffset,
      stemWidth: stemWidth,
      stemStart: stemStart,
      stemEnd: stemEnd,
      flagPainter: flagPainter,
      augmentationDotPainter: augmentationDotPainter,
      smufl: smufl,
      colour: colour,
      staveSpacing: staveSpacing,
    );
  }

  @override
  _GlyphMetrics get metrics => _GlyphMetrics(
        minWidth: [
          (accidentalPainter?.metrics.width ?? 0) + accidentalOffset.dx,
          noteheadPainter.metrics.width +
              noteheadOffset.dx +
              note.duration.dots * 1.5 * augmentationDotPainter.metrics.width,
          (flagPainter?.metrics.width ?? 0) + (stemEnd?.dx ?? 0),
        ].max,
        ascent: [
          (accidentalPainter?.boundingBox.north ?? 0) * staveSpacing -
              accidentalOffset.dy,
          noteheadPainter.boundingBox.north * staveSpacing - noteheadOffset.dy,
          (flagPainter?.boundingBox.north ?? 0) * staveSpacing -
              (stemEnd?.dy ?? 0),
        ].max,
        descent: [
          (accidentalPainter?.boundingBox.south ?? 0) * staveSpacing -
              (5 * staveSpacing - accidentalOffset.dy),
          noteheadPainter.boundingBox.south * staveSpacing -
              (5 * staveSpacing - noteheadOffset.dy),
          (flagPainter?.boundingBox.south ?? 0) * staveSpacing -
              (5 * staveSpacing - (stemEnd?.dy ?? 0)),
        ].max,
        duration: (note.duration.fractionOfSemibreve == 0
                ? 1
                : 1 / note.duration.fractionOfSemibreve) *
            (2.0 - pow(0.5, note.duration.dots)),
      );

  @override
  void layout({
    required double width,
    required double ascent,
    required double descent,
  }) {}

  @override
  void paint(Canvas canvas, {required Offset offset}) {
    final legerLineExtension = smufl.lelandMetadata['engravingDefaults']
            ['legerLineExtension'] *
        staveSpacing;

    drawLegerLine(double yOffset) {
      canvas.drawLine(
        offset +
            Offset(
              -legerLineExtension,
              (4 - yOffset) * staveSpacing,
            ),
        offset +
            Offset(
              metrics.minWidth + legerLineExtension,
              (4 - yOffset) * staveSpacing,
            ),
        Paint()
          ..color = colour
          ..strokeWidth = smufl.lelandMetadata['engravingDefaults']
                  ['legerLineThickness'] *
              staveSpacing,
      );
    }

    for (var y = 0.0; y >= yOffset; y -= 1) {
      drawLegerLine(y);
    }

    for (var y = 6.0; y <= yOffset; y += 1) {
      drawLegerLine(y);
    }

    if (accidentalPainter != null) {
      accidentalPainter!.paint(canvas, offset + accidentalOffset);
    }

    if (stemWidth != null && stemStart != null && stemEnd != null) {
      canvas.drawLine(
        offset + stemStart!,
        offset + stemEnd!,
        Paint()
          ..color = colour
          ..strokeWidth = stemWidth!,
      );
    }

    noteheadPainter.paint(canvas, offset + noteheadOffset);

    if (flagPainter != null && stemEnd != null) {
      flagPainter!.paint(canvas, offset + stemEnd!);
    }

    var augmentationDotOffset = noteheadOffset +
        Offset(noteheadPainter.metrics.width,
            yOffset % 2 == 1 ? -0.5 * staveSpacing : 0);
    for (var i = 0; i < note.duration.dots; i += 1) {
      augmentationDotOffset +=
          Offset(augmentationDotPainter.metrics.width / 2, 0);
      augmentationDotPainter.paint(canvas, offset + augmentationDotOffset);
      augmentationDotOffset += Offset(augmentationDotPainter.metrics.width, 0);
    }
  }
}

enum _BarlineComponent { thin, thick, dots }

@immutable
class _BarlinePainter extends _GlyphPainter {
  final BuiltList<_BarlineComponent> components;
  final BuiltList<double> separators;
  final BuiltMap<_BarlineComponent, double> widthOf;
  final _SMuFLPainter dotPainter;
  final Color colour;
  final double staveSpacing;

  const _BarlinePainter._init({
    required this.components,
    required this.separators,
    required this.widthOf,
    required this.dotPainter,
    required this.colour,
    required this.staveSpacing,
  }) : super._const();

  factory _BarlinePainter(
    final BuiltList<_BarlineComponent> components, {
    required final _MusicContext context,
    required final _SMuFL smufl,
    required final Color colour,
    required final double staveSpacing,
  }) {
    final separators = List.generate(
      components.length - 1,
      (index) {
        if (components[index] == _BarlineComponent.dots ||
            components[index + 1] == _BarlineComponent.dots) {
          return (smufl.lelandMetadata['engravingDefaults']
                      ['thinThickBarlineSeparation'] ??
                  smufl.lelandMetadata['engravingDefaults']
                      ['barlineSeparation']) *
              staveSpacing;
        } else if (components[index] == _BarlineComponent.thick ||
            components[index + 1] == _BarlineComponent.thick) {
          return smufl.lelandMetadata['engravingDefaults']
                  ['repeatBarlineDotSeparation'] *
              staveSpacing;
        } else {
          return smufl.lelandMetadata['engravingDefaults']
                  ['barlineSeparation'] *
              staveSpacing;
        }
      },
    ).cast<double>().toBuiltList();

    final dotPainter = _SMuFLPainter(
      smufl: smufl,
      smuflNames: ['repeatDots'],
      colour: colour,
      staveSpacing: staveSpacing,
    )..layout();

    final widthOf = BuiltMap.of({
      _BarlineComponent.thin: smufl.lelandMetadata['engravingDefaults']
              ['thinBarlineThickness'] *
          staveSpacing,
      _BarlineComponent.thick: smufl.lelandMetadata['engravingDefaults']
              ['thickBarlineThickness'] *
          staveSpacing,
      _BarlineComponent.dots: dotPainter.metrics.width,
    }.cast<_BarlineComponent, double>());

    context.accidentalAtYOffset = {};

    return _BarlinePainter._init(
      components: components,
      separators: separators,
      widthOf: widthOf,
      dotPainter: dotPainter,
      colour: colour,
      staveSpacing: staveSpacing,
    );
  }

  @override
  _GlyphMetrics get metrics => _GlyphMetrics(
        minWidth: components.map((component) => widthOf[component]!).sum +
            separators.sum,
        ascent: 0,
        descent: 0,
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
    var xOffset = 0.0;
    for (var i = 0; i < components.length; i += 1) {
      if (components[i] == _BarlineComponent.dots) {
        dotPainter.paint(canvas, offset + Offset(xOffset, 4 * staveSpacing));
      } else {
        canvas.drawLine(
          offset + Offset(xOffset + widthOf[components[i]]! / 2, 0),
          offset +
              Offset(xOffset + widthOf[components[i]]! / 2, 4 * staveSpacing),
          Paint()
            ..color = colour
            ..strokeWidth = widthOf[components[i]]!,
        );
      }
      xOffset += widthOf[components[i]]!;
      if (i < separators.length) {
        xOffset += separators[i];
      }
    }
  }
}

class _LyricPainter extends _GlyphPainter {
  final TextPainter painter;
  final double staveSpacing;
  Offset? offset2;

  _LyricPainter(
    Lyric lyric, {
    required final Color colour,
    required this.staveSpacing,
    required final double textSize,
  })  : painter = TextPainter(
          text: TextSpan(
            text: lyric.text,
            style: TextStyle(
              color: colour,
              fontSize: textSize,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
        super._const();

  @override
  _GlyphMetrics get metrics => _GlyphMetrics(
        minWidth: painter.width,
        ascent: 0,
        descent: 0,
        duration: 0,
      );

  @override
  void layout({
    required double width,
    required double ascent,
    required double descent,
  }) {
    offset2 = Offset(0, 4 * staveSpacing + descent);
  }

  @override
  void paint(Canvas canvas, {required Offset offset}) {
    painter.paint(canvas, offset + offset2!);
  }
}

@immutable
class _StavePainter extends CustomPainter {
  final Stave stave;
  final Color colour;
  final double textSize;
  final _SMuFL smufl;

  final double staveSpacing;

  const _StavePainter(
    this.stave, {
    required this.colour,
    required this.textSize,
    required this.smufl,
  }) : staveSpacing = textSize / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final painter = _HorizontalGroupPainter(
      stave.glyph,
      context: _MusicContext(),
      smufl: smufl,
      colour: colour,
      staveSpacing: staveSpacing,
      textSize: textSize,
    );

    final metrics = painter.metrics;

    painter.layout(
      width: size.width,
      ascent: metrics.ascent,
      descent: metrics.descent,
    );

    final width = painter.width;

    for (var i = 0; i < 5; i += 1) {
      final paint = Paint()
        ..color = colour
        ..strokeWidth = staveSpacing *
            smufl.lelandMetadata['engravingDefaults']['staffLineThickness'];
      canvas.drawLine(
        Offset(0, metrics.ascent + staveSpacing * i),
        Offset(width, metrics.ascent + staveSpacing * i),
        paint,
      );
    }

    painter.paint(canvas, offset: Offset(0, metrics.ascent));
  }

  @override
  bool shouldRepaint(covariant _StavePainter oldDelegate) {
    return stave != oldDelegate.stave || textSize != oldDelegate.textSize;
  }
}

@immutable
class StaveWidget extends StatelessWidget {
  final Stave stave;
  final Color colour;
  final double textSize;

  const StaveWidget(this.stave,
      {super.key, required this.colour, required this.textSize});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _SMuFL.load(),
        builder: (context, smufl) {
          if (smufl.hasData) {
            return CustomPaint(
              painter: _StavePainter(
                stave,
                colour: colour,
                textSize: textSize,
                smufl: smufl.data!,
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        });
  }
}
