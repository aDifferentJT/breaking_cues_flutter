import 'package:built_collection/built_collection.dart';
import 'package:meta/meta.dart';

import 'deck.dart';

@immutable
abstract class Message {
  const Message();

  factory Message.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'show':
        return ShowMessage.fromJson(json);
      default:
        return CloseMessage();
    }
  }

  Map<String, dynamic> toJson();
}

@immutable
class ShowMessage extends Message {
  final BuiltMap<String, DisplaySettings> defaultSettings;
  final bool quiet;
  final DeckIndex deckIndex;

  const ShowMessage({
    required this.defaultSettings,
    required this.quiet,
    required this.deckIndex,
  });

  ShowMessage.fromJson(Map<String, dynamic> json)
      : defaultSettings = BuiltMap.of(
          (json['defaultSettings'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, DisplaySettings.fromJson(value)),
          ),
        ),
        quiet = json['quiet'],
        deckIndex = DeckIndex.fromJson(json['deckIndex']);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'show',
        'defaultSettings': defaultSettings
            .asMap()
            .map((key, value) => MapEntry(key, value.toJson())),
        'quiet': quiet,
        'deckIndex': deckIndex.toJson(),
      };

  Slide get slide => deckIndex.slide;
}

@immutable
class CloseMessage extends Message {
  @override
  Map<String, dynamic> toJson() => {'type': 'close'};
}
