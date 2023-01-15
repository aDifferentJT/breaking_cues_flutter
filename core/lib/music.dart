import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';
import 'package:petitparser/petitparser.dart';

@immutable
class MusicOffset {
  final double dx;
  final double dy;

  const MusicOffset(this.dx, this.dy);

  MusicOffset operator +(MusicOffset that) =>
      MusicOffset(dx + that.dx, dy + that.dy);
}

@immutable
abstract class Glyph {
  const Glyph();

  static final Parser<Glyph> _parser = () {
    final glyphParser = undefined<Glyph>();
    glyphParser.set([
      VerticalGroup._parser(glyphParser),
      Clef._parser,
      KeySignature._parser,
      TimeSignature._parser,
      Note._parser,
      EndBarline._parser,
      Barline._parser,
      StartRepeat._parser,
      EndRepeat._parser,
      Lyric._parser,
    ].toChoiceParser());
    return resolve(glyphParser);
  }();

  String get _editText;
}

@immutable
class HorizontalGroup extends Glyph {
  final BuiltList<Glyph> glyphs;

  const HorizontalGroup(this.glyphs);

  static Parser<HorizontalGroup> _parser(Parser<Glyph> glyphParser) =>
      glyphParser
          .starSeparated(whitespace().plus())
          .map((glyphs) => HorizontalGroup(glyphs.elements.toBuiltList()));

  @override
  String get _editText => glyphs.map((glyph) => glyph._editText).join(' ');
}

@immutable
class VerticalGroup extends Glyph {
  final BuiltList<Glyph> glyphs;

  const VerticalGroup(this.glyphs);

  static Parser<VerticalGroup> _parser(Parser<Glyph> glyphParser) => glyphParser
      .starSeparated(whitespace().plus())
      .map((glyphs) => VerticalGroup(glyphs.elements.toBuiltList()))
      .skip(before: char('['), after: char(']'));

  @override
  String get _editText =>
      '[${glyphs.map((glyph) => glyph._editText).join(' ')}]';
}

enum BasePitch {
  C,
  D,
  E,
  F,
  G,
  A,
  B;

  static final Parser<BasePitch> _parser = [
    char('C').map((_) => BasePitch.C),
    char('D').map((_) => BasePitch.D),
    char('E').map((_) => BasePitch.E),
    char('F').map((_) => BasePitch.F),
    char('G').map((_) => BasePitch.G),
    char('A').map((_) => BasePitch.A),
    char('B').map((_) => BasePitch.B),
  ].toChoiceParser();

  @override
  String toString() {
    switch (this) {
      case BasePitch.C:
        return 'C';
      case BasePitch.D:
        return 'D';
      case BasePitch.E:
        return 'E';
      case BasePitch.F:
        return 'F';
      case BasePitch.G:
        return 'G';
      case BasePitch.A:
        return 'A';
      case BasePitch.B:
        return 'B';
    }
  }

  BasePitch get oneHigher {
    switch (this) {
      case BasePitch.C:
        return D;
      case BasePitch.D:
        return E;
      case BasePitch.E:
        return F;
      case BasePitch.F:
        return G;
      case BasePitch.G:
        return A;
      case BasePitch.A:
        return B;
      case BasePitch.B:
        return C;
    }
  }

  BasePitch get oneLower {
    switch (this) {
      case BasePitch.C:
        return B;
      case BasePitch.D:
        return C;
      case BasePitch.E:
        return D;
      case BasePitch.F:
        return E;
      case BasePitch.G:
        return F;
      case BasePitch.A:
        return G;
      case BasePitch.B:
        return A;
    }
  }
}

enum Accidental {
  natural,
  sharp,
  flat;

  static final Parser<Accidental> _parser = [
    char('#').map((_) => Accidental.sharp),
    char('b').map((_) => Accidental.flat),
  ].toChoiceParser().optionalWith(Accidental.natural);

  @override
  String toString() {
    switch (this) {
      case Accidental.natural:
        return '';
      case Accidental.sharp:
        return '#';
      case Accidental.flat:
        return 'b';
    }
  }
}

@immutable
class Pitch {
  final BasePitch basePitch;
  final Accidental accidental;
  final int octave;

  const Pitch({
    required this.basePitch,
    required this.accidental,
    required this.octave,
  });

  static final _parser = SequenceParser3(
    BasePitch._parser,
    Accidental._parser,
    digit().map(int.parse),
  ).map3((
    basePitch,
    accidental,
    octave,
  ) =>
      Pitch(
        basePitch: basePitch,
        accidental: accidental,
        octave: octave,
      ));

  @override
  toString() => '$basePitch$accidental$octave';

  String get _editText => toString();

  Pitch get oneSemitoneHigher {
    switch (accidental) {
      case Accidental.natural:
        if (basePitch == BasePitch.E || basePitch == BasePitch.B) {
          return Pitch(
            basePitch: basePitch.oneHigher,
            accidental: Accidental.natural,
            octave: basePitch == BasePitch.B ? octave + 1 : octave,
          );
        } else {
          return Pitch(
            basePitch: basePitch,
            accidental: Accidental.sharp,
            octave: octave,
          );
        }
      case Accidental.sharp:
        return Pitch(
          basePitch: basePitch.oneHigher,
          accidental: basePitch == BasePitch.E || basePitch == BasePitch.B
              ? Accidental.sharp
              : Accidental.natural,
          octave: basePitch == BasePitch.B ? octave + 1 : octave,
        );
      case Accidental.flat:
        return Pitch(
          basePitch: basePitch,
          accidental: Accidental.natural,
          octave: octave,
        );
    }
  }

  Pitch get oneSemitoneLower {
    switch (accidental) {
      case Accidental.natural:
        if (basePitch == BasePitch.C || basePitch == BasePitch.F) {
          return Pitch(
            basePitch: basePitch.oneLower,
            accidental: Accidental.natural,
            octave: basePitch == BasePitch.C ? octave - 1 : octave,
          );
        } else {
          return Pitch(
            basePitch: basePitch,
            accidental: Accidental.flat,
            octave: octave,
          );
        }
      case Accidental.sharp:
        return Pitch(
          basePitch: basePitch,
          accidental: Accidental.natural,
          octave: octave,
        );
      case Accidental.flat:
        return Pitch(
          basePitch: basePitch.oneLower,
          accidental: basePitch == BasePitch.C || basePitch == BasePitch.F
              ? Accidental.flat
              : Accidental.natural,
          octave: basePitch == BasePitch.C ? octave - 1 : octave,
        );
    }
  }

  Pitch operator +(int semitones) {
    if (semitones < 0) {
      return this - -semitones;
    } else {
      var pitch = this;
      for (int i = 0; i < semitones; i += 1) {
        pitch = pitch.oneSemitoneHigher;
      }
      return pitch;
    }
  }

  Pitch operator -(int semitones) {
    if (semitones < 0) {
      return this + -semitones;
    } else {
      var pitch = this;
      for (int i = 0; i < semitones; i += 1) {
        pitch = pitch.oneSemitoneLower;
      }
      return pitch;
    }
  }
}

@immutable
abstract class Clef extends Glyph {
  const Clef();

  static final Parser<Clef> _parser = [
    TrebleClef._parser,
    BassClef._parser,
    AltoClef._parser,
    TenorClef._parser,
  ].toChoiceParser();
}

@immutable
class TrebleClef extends Clef {
  const TrebleClef();

  static final Parser<TrebleClef> _parser =
      't'.toParser().map((_) => const TrebleClef());

  @override
  get _editText => 't';
}

@immutable
class BassClef extends Clef {
  const BassClef();

  static final Parser<BassClef> _parser =
      'b'.toParser().map((_) => const BassClef());

  @override
  get _editText => 'b';
}

@immutable
class AltoClef extends Clef {
  const AltoClef();

  static final Parser<AltoClef> _parser =
      'a'.toParser().map((_) => const AltoClef());

  @override
  get _editText => 'a';
}

@immutable
class TenorClef extends Clef {
  const TenorClef();

  static final Parser<TenorClef> _parser =
      't'.toParser().map((_) => const TenorClef());

  @override
  get _editText => 't';
}

@immutable
class KeySignature extends Glyph {
  final int _numSharps; // Flats are negative
  int get _numFlats => -_numSharps;

  bool get isSharp => _numSharps > 0;

  const KeySignature.sharps(final int numSharps) : _numSharps = numSharps;
  const KeySignature.flats(final int numFlats) : _numSharps = -numFlats;

  factory KeySignature(
    final Pitch note, {
    required final bool minor,
  }) {
    final majorNote = minor ? note + 3 : note;

    final numSharps = (Pitch note) {
      int numSharps = 0;
      while (note.basePitch != BasePitch.C ||
          note.accidental != Accidental.natural) {
        note -= 7;
        numSharps += 1;
      }
      return numSharps;
    }(majorNote);

    final numFlats = (Pitch note) {
      int numFlats = 0;
      while (note.basePitch != BasePitch.C ||
          note.accidental != Accidental.natural) {
        note += 7;
        numFlats += 1;
      }
      return numFlats;
    }(majorNote);

    switch (note.accidental) {
      case Accidental.natural:
        return numSharps < numFlats
            ? KeySignature.sharps(numSharps)
            : KeySignature.flats(numFlats);
      case Accidental.sharp:
        return numSharps <= 7
            ? KeySignature.sharps(numSharps)
            : KeySignature.flats(numFlats);
      case Accidental.flat:
        return numFlats <= 7
            ? KeySignature.flats(numFlats)
            : KeySignature.sharps(numSharps);
    }
  }

  Pitch get pitch =>
      const Pitch(
        basePitch: BasePitch.C,
        accidental: Accidental.natural,
        octave: 0,
      ) +
      _numSharps * 7;

  static const _sharpOrder = [
    BasePitch.F,
    BasePitch.C,
    BasePitch.G,
    BasePitch.D,
    BasePitch.A,
    BasePitch.E,
    BasePitch.B,
  ];

  static List<BasePitch> get _flatOrder =>
      _sharpOrder.reversed.toList(growable: false);

  List<BasePitch> get sharps => _sharpOrder.sublist(0, max(0, _numSharps));
  List<BasePitch> get flats => _flatOrder.sublist(0, max(0, _numFlats));

  static final Parser<KeySignature> _parser = SequenceParser2(
    Pitch._parser,
    char('m').map((_) => true).optionalWith(false),
  ).map2((pitch, minor) => KeySignature(pitch, minor: minor));

  @override
  get _editText => pitch._editText;
}

@immutable
class TimeSignature extends Glyph {
  final int upper;
  final int lower;

  const TimeSignature(this.upper, this.lower);

  static final Parser<TimeSignature> _parser = SequenceParser3(
    digit().plus().flatten().map(int.parse),
    char('/'),
    digit().plus().flatten().map(int.parse),
  ).map3((upper, _, lower) => TimeSignature(upper, lower));

  @override
  get _editText => '$upper/$lower';
}

class NoteDuration {
  final int fractionOfSemibreve;
  final int dots;

  const NoteDuration({required this.fractionOfSemibreve, required this.dots});

  static final Parser<NoteDuration> _parser = SequenceParser2(
    digit().plus().flatten().map(int.parse),
    char('.').star(),
  ).map2(
    (fractionOfSemibreve, dots) => NoteDuration(
      fractionOfSemibreve: fractionOfSemibreve,
      dots: dots.length,
    ),
  );

  String get _editText =>
      '$fractionOfSemibreve${List.filled(dots, '.').join()}';

  @override
  bool operator ==(Object other) =>
      other is NoteDuration && fractionOfSemibreve == other.fractionOfSemibreve;

  @override
  int get hashCode => fractionOfSemibreve.hashCode;
}

@immutable
class Note extends Glyph {
  final NoteDuration duration;
  final Pitch pitch;

  const Note({
    required this.duration,
    required this.pitch,
  });

  static final Parser<Note> _parser = SequenceParser2(
    NoteDuration._parser,
    Pitch._parser,
  ).map2((
    duration,
    pitch,
  ) =>
      Note(
        duration: duration,
        pitch: pitch,
      ));

  @override
  get _editText => '${duration._editText}${pitch._editText}';
}

@immutable
class Barline extends Glyph {
  const Barline();

  static final Parser<Barline> _parser =
      '|'.toParser().map((_) => const Barline());

  @override
  get _editText => '|';
}

@immutable
class EndBarline extends Glyph {
  const EndBarline();

  static final Parser<EndBarline> _parser =
      '||'.toParser().map((_) => const EndBarline());

  @override
  get _editText => '||';
}

@immutable
class StartRepeat extends Glyph {
  const StartRepeat();

  static final Parser<StartRepeat> _parser =
      '||:'.toParser().map((_) => const StartRepeat());

  @override
  get _editText => '||:';
}

@immutable
class EndRepeat extends Glyph {
  const EndRepeat();

  static final Parser<EndRepeat> _parser =
      ':||'.toParser().map((_) => const EndRepeat());

  @override
  get _editText => ':||';
}

@immutable
class Lyric extends Glyph {
  final String text;

  const Lyric(this.text);

  static final Parser<Lyric> _parser = pattern('^"')
      .star()
      .flatten()
      .map((text) => Lyric(text))
      .skip(before: char('"'), after: char('"'));

  @override
  get _editText => '"$text"';
}

@immutable
class Stave {
  final HorizontalGroup glyph;

  const Stave(
    this.glyph,
  );

  static final Parser<Stave> parser =
      HorizontalGroup._parser(Glyph._parser).map(Stave.new);

  String get editText => glyph._editText;

  String get lyrics => '';

  factory Stave.fromJson(final String json) =>
      parser.end().parse(json.replaceAll('\\"', '"')).value;
  String get toJson => editText.replaceAll('"', '\\"');
}
