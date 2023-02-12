import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:core/music.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    print('loading smufl');
    final smufl = SMuFL._byParts(
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
    print('loaded smufl');
    return smufl;
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

  TextSpan textSpan(
    final Iterable<String> smuflNames, {
    TextStyle style = const TextStyle(),
    bool inline = false,
  }) {
    print('Leland${inline ? 'Text' : ''}');
    return TextSpan(
      text: smuflNames.map(glyph).join(),
      style: style.copyWith(
        fontFamily: inline ? 'BravuraText' : 'Leland',
        textBaseline: TextBaseline.alphabetic,
        package: 'fonts',
      ),
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
    BaseGlyph glyph, {
    required SMuFL smufl,
    required Color colour,
    required double staveSpacing,
    required double textSize,
  }) {
    if (glyph is Clef) {
      return _ClefPainter(
        glyph,
        smufl: smufl,
        colour: colour,
        staveSpacing: staveSpacing,
      );
    } else if (glyph is Note) {
      throw 'hi';
      // return _NotePainter(
      //   glyph,
      //   context: context,
      //   smufl: smufl,
      //   colour: colour,
      //   staveSpacing: staveSpacing,
      // );
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
  final _GlyphPainter painter;
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
class _ClefPainter extends _GlyphPainter {
  final _SMuFLPainter painter;
  final double yOffset;
  final double staveSpacing;

  _ClefPainter(
    Clef clef, {
    required SMuFL smufl,
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
        super._const();

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
class _StavePainter extends CustomPainter {
  final Stave stave;
  final Color colour;
  final double textSize;
  final SMuFL smufl;

  final double staveSpacing;

  const _StavePainter(
    this.stave, {
    required this.colour,
    required this.textSize,
    required this.smufl,
  }) : staveSpacing = textSize / 2;

  @override
  void paint(Canvas canvas, Size size) {
    for (final glyph in stave.baseGlyphs) {
      final painter = _GlyphPainter(
        glyph,
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

      painter.paint(canvas, offset: Offset(0, metrics.ascent));
    }

    final width = 100.0;
    final metrics =
        _GlyphMetrics(minWidth: 0, ascent: 0, descent: 0, duration: 0);

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
      future: SMuFL.load(),
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
      },
    );
  }
}
