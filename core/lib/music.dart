import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

@immutable
abstract class Glyph {
  const Glyph();
}

@immutable
abstract class Clef extends Glyph {
  const Clef();
}

@immutable
class TrebleClef extends Clef {
  const TrebleClef();
}

@immutable
class BassClef extends Clef {
  const BassClef();
}

@immutable
class AltoClef extends Clef {
  const AltoClef();
}

@immutable
class TenorClef extends Clef {
  const TenorClef();
}

@immutable
class NoteDuration {
  final int fractionOfSemibreve;
  final int numAugmentationDots;

  const NoteDuration({
    required this.fractionOfSemibreve,
    this.numAugmentationDots = 0,
  });

  NoteDuration addAugmentationDot() => NoteDuration(
        fractionOfSemibreve: fractionOfSemibreve,
        numAugmentationDots: numAugmentationDots + 1,
      );
}

@immutable
class NotePitch {
  final int distanceDownFromCentre;

  const NotePitch({required this.distanceDownFromCentre});

  bool operator ==(Object other) =>
      other is NotePitch &&
      distanceDownFromCentre == other.distanceDownFromCentre;

  @override
  int get hashCode => distanceDownFromCentre.hashCode;
}

@immutable
class Chord extends Glyph {
  final NoteDuration? duration;
  final BuiltSet<NotePitch> pitches;

  const Chord({required this.duration, required this.pitches});

  Chord addAugmentationDot() => Chord(
        duration: duration?.addAugmentationDot(),
        pitches: pitches,
      );

  Chord addPitch(NotePitch pitch) => Chord(
        duration: duration,
        pitches: pitches.rebuild((pitches) => pitches.add(pitch)),
      );
}

@immutable
class Stave {
  final BuiltList<Glyph> baseGlyphs;

  const Stave(this.baseGlyphs);

  String get lyrics => '';

  Stave withBaseGlyphs(BuiltList<Glyph> baseGlyphs) => Stave(baseGlyphs);
  Stave rebuildBaseGlyphs(void Function(ListBuilder<Glyph>) updates) =>
      withBaseGlyphs(baseGlyphs.rebuild(updates));
}

@immutable
class SpacedGlyph {
  final Glyph glyph;
  final double width;

  const SpacedGlyph(this.glyph, {required this.width});
}
