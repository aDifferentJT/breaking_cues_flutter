import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

@immutable
abstract class BaseGlyph {
  const BaseGlyph();
}

@immutable
abstract class Clef extends BaseGlyph {
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
  const NoteDuration();
}

@immutable
class NotePosition {
  const NotePosition();
}

@immutable
class Note extends BaseGlyph {
  final NoteDuration duration;
  final NotePosition position;

  const Note({required this.duration, required this.position});
}

@immutable
class Stave {
  final BuiltList<BaseGlyph> baseGlyphs;

  const Stave(
    this.baseGlyphs,
  );

  String get lyrics => '';
}
