import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:core/music.dart';
import 'package:meta/meta.dart';
import 'package:petitparser/petitparser.dart';

@immutable
class Colour {
  final int a;
  final int r;
  final int g;
  final int b;

  const Colour({
    required this.a,
    required this.r,
    required this.g,
    required this.b,
  });

  Colour.fromJson(Map<String, dynamic> json)
      : a = json['a'],
        r = json['r'],
        g = json['g'],
        b = json['b'];

  Map<String, dynamic> toJson() => {'a': a, 'r': r, 'g': g, 'b': b};

  Colour withAlpha(int a) => Colour(a: a, r: r, g: g, b: b);
}

enum Style {
  none,
  leftQuarter,
  leftThird,
  leftHalf,
  leftTwoThirds,
  rightQuarter,
  rightThird,
  rightHalf,
  rightTwoThirds,
  topLines,
  bottomLines,
  bottomParagraphs,
  fullScreen;

  factory Style.fromJson(int index) => values[index];
  int toJson() => index;
}

@immutable
class LiturgicalColours {
  static const gold = Colour(a: 0x7F, r: 255, g: 240, b: 200);
}

@immutable
class DisplaySettings {
  final Style style;
  final Colour backgroundColour;
  final Colour textColour;
  final String fontFamily;
  final double titleSize;
  final double subtitleSize;
  final double bodySize;

  const DisplaySettings({
    required this.style,
    required this.backgroundColour,
    required this.textColour,
    required this.fontFamily,
    required this.titleSize,
    required this.subtitleSize,
    required this.bodySize,
  });

  const DisplaySettings.default_()
      : style = Style.bottomLines,
        backgroundColour = LiturgicalColours.gold,
        textColour = const Colour(a: 0xFF, r: 0, g: 0, b: 0),
        fontFamily = 'URWBookman',
        titleSize = 75,
        subtitleSize = 25,
        bodySize = 50;

  DisplaySettings withStyle(Style style) => DisplaySettings(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  DisplaySettings withBackgroundColour(Colour backgroundColour) =>
      DisplaySettings(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  DisplaySettings withTextColour(Colour textColour) => DisplaySettings(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  DisplaySettings withFontFamily(String fontFamily) => DisplaySettings(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  DisplaySettings withTitleSize(double titleSize) => DisplaySettings(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  DisplaySettings withSubtitleSize(double subtitleSize) => DisplaySettings(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  DisplaySettings withBodySize(double bodySize) => DisplaySettings(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  DisplaySettings.fromJson(Map<String, dynamic> json)
      : style = Style.fromJson(json['style']),
        backgroundColour = Colour.fromJson(json['backgroundColour']),
        textColour = Colour.fromJson(json['textColour']),
        fontFamily = json['fontFamily'],
        titleSize = json['titleSize'],
        subtitleSize = json['subtitleSize'],
        bodySize = json['bodySize'];

  Map<String, dynamic> toJson() => {
        'style': style.toJson(),
        'backgroundColour': backgroundColour.toJson(),
        'textColour': textColour.toJson(),
        'fontFamily': fontFamily,
        'titleSize': titleSize,
        'subtitleSize': subtitleSize,
        'bodySize': bodySize,
      };
}

@immutable
class OptionalDisplaySettings {
  final Style? style;
  final Colour? backgroundColour;
  final Colour? textColour;
  final String? fontFamily;
  final double? titleSize;
  final double? subtitleSize;
  final double? bodySize;

  const OptionalDisplaySettings()
      : style = null,
        backgroundColour = null,
        textColour = null,
        fontFamily = null,
        titleSize = null,
        subtitleSize = null,
        bodySize = null;

  const OptionalDisplaySettings._byParts({
    required this.style,
    required this.backgroundColour,
    required this.textColour,
    required this.fontFamily,
    required this.titleSize,
    required this.subtitleSize,
    required this.bodySize,
  });

  OptionalDisplaySettings.fromJson(Map<String, dynamic> json)
      : style = json['style'] != null ? Style.fromJson(json['style']) : null,
        backgroundColour = json['backgroundColour'] != null
            ? Colour.fromJson(json['backgroundColour'])
            : null,
        textColour = json['textColour'] != null
            ? Colour.fromJson(json['textColour'])
            : null,
        fontFamily = json['fontFamily'],
        titleSize = json['titleSize'],
        subtitleSize = json['subtitleSize'],
        bodySize = json['bodySize'];

  Map<String, dynamic> toJson() => {
        'style': style?.toJson(),
        'backgroundColour': backgroundColour?.toJson(),
        'textColour': textColour?.toJson(),
        'titleSize': titleSize,
        'subtitleSize': subtitleSize,
        'bodySize': bodySize,
      };

  DisplaySettings withDefaults(DisplaySettings defaults) => DisplaySettings(
        style: style ?? defaults.style,
        backgroundColour: backgroundColour ?? defaults.backgroundColour,
        textColour: textColour ?? defaults.textColour,
        fontFamily: fontFamily ?? defaults.fontFamily,
        titleSize: titleSize ?? defaults.titleSize,
        subtitleSize: subtitleSize ?? defaults.subtitleSize,
        bodySize: bodySize ?? defaults.bodySize,
      );

  OptionalDisplaySettings withStyle(Style? style) =>
      OptionalDisplaySettings._byParts(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  OptionalDisplaySettings withBackgroundColour(Colour? backgroundColour) =>
      OptionalDisplaySettings._byParts(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  OptionalDisplaySettings withTextColour(Colour? textColour) =>
      OptionalDisplaySettings._byParts(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  OptionalDisplaySettings withFontFamily(String? fontFamily) =>
      OptionalDisplaySettings._byParts(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  OptionalDisplaySettings withTitleSize(double? titleSize) =>
      OptionalDisplaySettings._byParts(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  OptionalDisplaySettings withSubtitleSize(double? subtitleSize) =>
      OptionalDisplaySettings._byParts(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );

  OptionalDisplaySettings withBodySize(double? bodySize) =>
      OptionalDisplaySettings._byParts(
        style: style,
        backgroundColour: backgroundColour,
        textColour: textColour,
        fontFamily: fontFamily,
        titleSize: titleSize,
        subtitleSize: subtitleSize,
        bodySize: bodySize,
      );
}

@immutable
abstract class Slide {
  String get label;
}

@immutable
abstract class Chunk {
  BuiltList<Slide> get slides;

  factory Chunk.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'countdown':
        return CountdownChunk.fromJson(json);
      case 'title':
        return TitleChunk.fromJson(json);
      case 'music':
        return MusicChunk.fromJson(json);
      default:
        return BodyChunk.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();
}

@immutable
class CountdownChunk with Chunk, Slide {
  final String title;
  final String subtitle1;
  final String subtitle2;
  final String message;
  final String whenStopped;
  final DateTime countdownTo;
  final Duration stopAt;

  const CountdownChunk({
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    required this.message,
    required this.whenStopped,
    required this.countdownTo,
    required this.stopAt,
  });

  static CountdownChunk get default_ {
    final now = DateTime.now();
    return CountdownChunk(
      title: 'Title',
      subtitle1: 'Subtitle 1',
      subtitle2: 'Subtitle 2',
      message: 'The service will begin in #',
      whenStopped: 'The service will begin shortly',
      countdownTo: DateTime(now.year, now.month, now.day, now.hour + 1),
      stopAt: const Duration(minutes: 1),
    );
  }

  CountdownChunk withTitle(String title) => CountdownChunk(
        title: title,
        subtitle1: subtitle1,
        subtitle2: subtitle2,
        message: message,
        whenStopped: whenStopped,
        countdownTo: countdownTo,
        stopAt: stopAt,
      );
  CountdownChunk withSubtitle1(String subtitle1) => CountdownChunk(
        title: title,
        subtitle1: subtitle1,
        subtitle2: subtitle2,
        message: message,
        whenStopped: whenStopped,
        countdownTo: countdownTo,
        stopAt: stopAt,
      );
  CountdownChunk withSubtitle2(String subtitle2) => CountdownChunk(
        title: title,
        subtitle1: subtitle1,
        subtitle2: subtitle2,
        message: message,
        whenStopped: whenStopped,
        countdownTo: countdownTo,
        stopAt: stopAt,
      );
  CountdownChunk withMessage(String message) => CountdownChunk(
        title: title,
        subtitle1: subtitle1,
        subtitle2: subtitle2,
        message: message,
        whenStopped: whenStopped,
        countdownTo: countdownTo,
        stopAt: stopAt,
      );
  CountdownChunk withWhenStopped(String whenStopped) => CountdownChunk(
        title: title,
        subtitle1: subtitle1,
        subtitle2: subtitle2,
        message: message,
        whenStopped: whenStopped,
        countdownTo: countdownTo,
        stopAt: stopAt,
      );
  CountdownChunk withCountdownTo(DateTime countdownTo) => CountdownChunk(
        title: title,
        subtitle1: subtitle1,
        subtitle2: subtitle2,
        message: message,
        whenStopped: whenStopped,
        countdownTo: countdownTo,
        stopAt: stopAt,
      );
  CountdownChunk withStopAt(Duration stopAt) => CountdownChunk(
        title: title,
        subtitle1: subtitle1,
        subtitle2: subtitle2,
        message: message,
        whenStopped: whenStopped,
        countdownTo: countdownTo,
        stopAt: stopAt,
      );

  CountdownChunk.fromJson(Map<String, dynamic> json)
      : this(
          title: json['title'],
          subtitle1: json['subtitle1'],
          subtitle2: json['subtitle2'],
          message: json['message'],
          whenStopped: json['whenStopped'],
          countdownTo: DateTime.tryParse(json['countdownTo']) ?? DateTime(1970),
          stopAt: Duration(microseconds: json['stopAt']),
        );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'countdown',
        'title': title,
        'subtitle1': subtitle1,
        'subtitle2': subtitle2,
        'message': message,
        'countdownTo': countdownTo.toIso8601String(),
        'stopAt': stopAt.inMicroseconds,
        'whenStopped': whenStopped,
      };

  @override
  BuiltList<Slide> get slides => BuiltList([this]);

  @override
  String get label => 'Countdown to '
      '${countdownTo.hour.toString().padLeft(2, '0')}:'
      '${countdownTo.minute.toString().padLeft(2, '0')}:'
      '${countdownTo.second.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) {
    return other is CountdownChunk &&
        title == other.title &&
        subtitle1 == other.subtitle1 &&
        subtitle2 == other.subtitle2 &&
        message == other.message &&
        whenStopped == other.whenStopped &&
        countdownTo == other.countdownTo &&
        stopAt == other.stopAt;
  }

  @override
  int get hashCode => Object.hash(
        title,
        subtitle1,
        subtitle2,
        message,
        whenStopped,
        countdownTo,
        stopAt,
      );
}

@immutable
class TitleChunk with Chunk, Slide {
  final String title;
  final String subtitle;

  const TitleChunk({required this.title, required this.subtitle});

  TitleChunk withTitle(String title) =>
      TitleChunk(title: title, subtitle: subtitle);
  TitleChunk withSubtitle(String subtitle) =>
      TitleChunk(title: title, subtitle: subtitle);

  TitleChunk.fromJson(Map<String, dynamic> json)
      : this(
          title: json['title'],
          subtitle: json['subtitle'],
        );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'title',
        'title': title,
        'subtitle': subtitle,
      };

  @override
  BuiltList<Slide> get slides => BuiltList([this]);

  @override
  String get label => '$title\n$subtitle';

  @override
  bool operator ==(Object other) {
    return other is TitleChunk &&
        title == other.title &&
        subtitle == other.subtitle;
  }

  @override
  int get hashCode => Object.hash(title, subtitle);
}

@immutable
class BodySlide with Slide {
  final BuiltList<String> minorChunks;
  final int minorIndex;

  const BodySlide({required this.minorChunks, required this.minorIndex});

  String get minorChunk => minorChunks[minorIndex];

  @override
  String get label => minorChunk;
}

@immutable
class BodyChunk with Chunk {
  final BuiltList<String> minorChunks;

  const BodyChunk({required this.minorChunks});

  BodyChunk withMinorChunks(BuiltList<String> minorChunks) =>
      BodyChunk(minorChunks: minorChunks);
  BodyChunk rebuildMinorChunks(void Function(ListBuilder<String>) updates) =>
      BodyChunk(minorChunks: minorChunks.rebuild(updates));

  BodyChunk.parse(String text)
      : this(minorChunks: text.split('\n\n').toBuiltList());

  BodyChunk.fromJson(Map<String, dynamic> json)
      : minorChunks =
            (json['minorChunks'] as Iterable).cast<String>().toBuiltList();

  @override
  Map<String, dynamic> toJson() => {
        'type': 'body',
        'minorChunks': minorChunks.toList(growable: false),
      };

  @override
  BuiltList<BodySlide> get slides => minorChunks
      .mapIndexed(
          (index, _) => BodySlide(minorChunks: minorChunks, minorIndex: index))
      .toBuiltList();

  @override
  bool operator ==(Object other) {
    return other is BodyChunk && minorChunks == other.minorChunks;
  }

  @override
  int get hashCode => Object.hashAll(minorChunks);
}

@immutable
class MusicSlide with Slide {
  final BuiltList<Stave> minorChunks;
  final int minorIndex;

  const MusicSlide({required this.minorChunks, required this.minorIndex});

  Stave get minorChunk => minorChunks[minorIndex];

  @override
  String get label => minorChunk.lyrics;
}

@immutable
class MusicChunk with Chunk {
  final BuiltList<Stave> minorChunks;

  const MusicChunk({required this.minorChunks});

  MusicChunk withMinorChunks(BuiltList<Stave> minorChunks) =>
      MusicChunk(minorChunks: minorChunks);

  MusicChunk.fromJson(Map<String, dynamic> json) : minorChunks = BuiltList();

  @override
  Map<String, dynamic> toJson() => {
        'type': 'music',
        'minorChunks': minorChunks.map((stave) => {}).toList(growable: false),
      };

  @override
  BuiltList<MusicSlide> get slides => minorChunks
      .mapIndexed(
          (index, _) => MusicSlide(minorChunks: minorChunks, minorIndex: index))
      .toBuiltList();

  @override
  bool operator ==(Object other) {
    return other is MusicChunk && minorChunks == other.minorChunks;
  }

  @override
  int get hashCode => Object.hashAll(minorChunks);
}

@immutable
class DeckKey {
  final int key;

  const DeckKey(this.key);

  DeckKey.distinctFrom(Iterable<DeckKey> keys)
      : key = (keys.map((key) => key.key).maxOrNull ?? 0) + 1;

  @override
  bool operator ==(Object other) {
    return other is DeckKey && key == other.key;
  }

  @override
  int get hashCode => key;
}

@immutable
class Deck {
  final DeckKey key;
  final BuiltMap<String, OptionalDisplaySettings> displaySettings;
  final String comment;
  final BuiltList<Chunk> chunks;

  Deck({
    required this.key,
    BuiltMap<String, OptionalDisplaySettings>? displaySettings,
    this.comment = '',
    BuiltList<Chunk>? chunks,
  })  : displaySettings = displaySettings ?? BuiltMap(),
        chunks = chunks ?? BuiltList();

  Deck.fromJson(Map<String, dynamic> json)
      : key = DeckKey(json['key']),
        displaySettings = BuiltMap.of(
          (json['displaySettings'] as Map<String, dynamic>).map(
            (key, value) =>
                MapEntry(key, OptionalDisplaySettings.fromJson(value)),
          ),
        ),
        comment = json['comment'],
        chunks = (json['chunks'] as Iterable)
            .cast<Map<String, dynamic>>()
            .map(Chunk.fromJson)
            .toBuiltList();

  Map<String, dynamic> toJson() => {
        'key': key.key,
        'displaySettings': displaySettings
            .asMap()
            .map((key, value) => MapEntry(key, value.toJson())),
        'comment': comment,
        'chunks': chunks.map((chunk) => chunk.toJson()).toList(growable: false),
      };

  String get label {
    if (comment != '') {
      return comment;
    } else if (chunks.isNotEmpty &&
        chunks[0].slides.isNotEmpty &&
        chunks[0].slides[0].label.isNotEmpty) {
      return chunks[0].slides[0].label.split('\n')[0];
    } else {
      return '';
    }
  }

  Deck withDisplaySettings(
    BuiltMap<String, OptionalDisplaySettings>? displaySettings,
  ) =>
      Deck(
        key: key,
        displaySettings: displaySettings,
        comment: comment,
        chunks: chunks,
      );

  Deck withComment(String comment) => Deck(
        key: key,
        displaySettings: displaySettings,
        comment: comment,
        chunks: chunks,
      );

  Deck withChunks(BuiltList<Chunk> chunks) => Deck(
        key: key,
        displaySettings: displaySettings,
        comment: comment,
        chunks: chunks,
      );

  Deck rebuildChunks(void Function(ListBuilder<Chunk>) updates) => Deck(
        key: key,
        displaySettings: displaySettings,
        comment: comment,
        chunks: chunks.rebuild(updates),
      );

  @override
  bool operator ==(Object other) =>
      other is Deck &&
      key == other.key &&
      // displaySettings == other.displaySettings && TODO
      comment == other.comment &&
      chunks == other.chunks;

  @override
  int get hashCode =>
      Object.hash(key, displaySettings, comment, Object.hashAll(chunks));
}

@immutable
class Index {
  final int chunk;
  final int slide;

  const Index({required this.chunk, required this.slide});

  static const zero = Index(chunk: 0, slide: 0);

  Index.fromJson(Map<String, dynamic> json)
      : chunk = json['chunk'],
        slide = json['slide'];

  Map<String, dynamic> toJson() => {
        'chunk': chunk,
        'slide': slide,
      };

  @override
  bool operator ==(Object other) =>
      other is Index && chunk == other.chunk && slide == other.slide;

  @override
  int get hashCode => Object.hash(chunk, slide);
}

@immutable
class DeckIndex {
  final Deck deck;
  final Index index;

  const DeckIndex({required this.deck, required this.index});

  DeckIndex.fromJson(Map<String, dynamic> json)
      : deck = Deck.fromJson(json['deck']),
        index = Index.fromJson(json['index']);

  Map<String, dynamic> toJson() => {
        'deck': deck.toJson(),
        'index': index.toJson(),
      };

  Slide get slide {
    if (index.chunk < deck.chunks.length) {
      final chunk = deck.chunks[index.chunk];
      if (index.slide >= 0 && index.slide < chunk.slides.length) {
        return chunk.slides[index.slide];
      }
    }
    return const TitleChunk(title: '', subtitle: '');
  }

  DeckIndex withDeck(Deck deck) => DeckIndex(deck: deck, index: index);

  @override
  bool operator ==(Object other) =>
      other is DeckIndex && deck == other.deck && index == other.index;

  @override
  int get hashCode => Object.hash(deck, index);
}

@immutable
class Programme {
  final BuiltMap<String, DisplaySettings> defaultSettings;
  final BuiltList<Deck> decks;

  const Programme({required this.defaultSettings, required this.decks});

  Programme.new_()
      : defaultSettings = BuiltMap(const {
          'Broadcast': DisplaySettings(
            style: Style.bottomLines,
            backgroundColour: LiturgicalColours.gold,
            textColour: Colour(a: 0xff, r: 0xff, g: 0xff, b: 0xff),
            fontFamily: 'URWBookman',
            titleSize: 75,
            subtitleSize: 25,
            bodySize: 50,
          ),
          'House': DisplaySettings(
            style: Style.leftThird,
            backgroundColour: LiturgicalColours.gold,
            textColour: Colour(a: 0xff, r: 0xff, g: 0xff, b: 0xff),
            fontFamily: 'URWBookman',
            titleSize: 75,
            subtitleSize: 25,
            bodySize: 50,
          ),
        }),
        decks = BuiltList([
          Deck(
              key: const DeckKey(1),
              chunks: BuiltList([
                BodyChunk(minorChunks: BuiltList(['Slide 1', 'Slide 2'])),
                BodyChunk(minorChunks: BuiltList(['Slide 1\nSlide 2'])),
              ])),
          Deck(
              key: const DeckKey(2),
              comment: 'Deck 2',
              chunks: BuiltList([
                BodyChunk(minorChunks: BuiltList(['Slide 1', 'Slide 2'])),
                BodyChunk(minorChunks: BuiltList(['Slide 1\nSlide 2'])),
              ])),
        ]);

  Programme.fromJson(Map<String, dynamic> json)
      : defaultSettings = BuiltMap.of(
          (json['defaultSettings'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, DisplaySettings.fromJson(value)),
          ),
        ),
        decks = (json['decks'] as Iterable)
            .cast<Map<String, dynamic>>()
            .map(Deck.fromJson)
            .toBuiltList();

  Map<String, dynamic> toJson() => {
        'defaultSettings': defaultSettings
            .asMap()
            .map((key, value) => MapEntry(key, value.toJson())),
        'decks': decks.map((deck) => deck.toJson()).toList(growable: false),
      };

  Programme withDecks(BuiltList<Deck> decks) =>
      Programme(defaultSettings: defaultSettings, decks: decks);
  Programme mapDecks(BuiltList<Deck> Function(BuiltList<Deck>) f) =>
      Programme(defaultSettings: defaultSettings, decks: f(decks));

  Programme withDefaultSettings(
          BuiltMap<String, DisplaySettings> defaultSettings) =>
      Programme(defaultSettings: defaultSettings, decks: decks);
}
