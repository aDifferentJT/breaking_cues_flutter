import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';

import 'bible.dart';
import 'package:core/deck.dart';

@immutable
abstract class Suggestion {
  const Suggestion(this.title);

  final String title;

  Deck body();
}

@immutable
abstract class Suggestor {
  const Suggestor();

  BuiltList<Suggestion> results(String cue);
  BuiltSet<String> completions(String cue);
}

@immutable
class CollateSuggestors extends Suggestor {
  const CollateSuggestors(this._suggestors);

  final BuiltList<Suggestor> _suggestors;

  @override
  BuiltList<Suggestion> results(String cue) =>
      _suggestors.expand((suggestor) => suggestor.results(cue)).toBuiltList();

  @override
  BuiltSet<String> completions(String cue) =>
      _suggestors.expand((element) => completions(cue)).toBuiltSet();
}

@immutable
abstract class RegexSuggestor extends Suggestor {
  const RegexSuggestor(this.regex);

  final RegExp regex;

  BuiltList<Suggestion> suggestionsForMatch(Match match);

  @override
  BuiltList<Suggestion> results(String cue) {
    final match = regex.firstMatch(cue);
    if (match != null && match.start == 0 && match.end == cue.length) {
      return suggestionsForMatch(match);
    } else {
      return BuiltList();
    }
  }
}

@immutable
class BCPPsalmSuggestion extends Suggestion {
  const BCPPsalmSuggestion(int number, {int? start, int? end})
      : super("Psalm $number (BCP)");

  @override
  Deck body() {
    // TODO: implement body
    throw UnimplementedError();
  }
}

@immutable
class PsalmSuggestor extends RegexSuggestor {
  PsalmSuggestor() : super(RegExp(r"Psalm +(\d+)", caseSensitive: false));

  @override
  BuiltList<Suggestion> suggestionsForMatch(Match match) {
    final psalmNumberString = match.group(1);
    if (psalmNumberString != null) {
      final psalmNumber = int.tryParse(psalmNumberString);
      if (psalmNumber != null && psalmNumber >= 1 && psalmNumber <= 150) {
        return BuiltList([BCPPsalmSuggestion(psalmNumber)]);
      }
    }
    return BuiltList();
  }

  @override
  BuiltSet<String> completions(String cue) {
    if (cue.toLowerCase().matchAsPrefix("psalm") != null) {
      return BuiltSet({"Psalm "});
    } else {
      return BuiltSet();
    }
  }
}

@immutable
class BibleSuggestor extends Suggestor {
  @override
  BuiltSet<String> completions(String cue) {
    return bibleBookMatcher
        .match(cue)
        .map((completion) => "$completion ")
        .toBuiltSet();
  }

  @override
  BuiltList<Suggestion> results(String cue) {
    return BuiltList();
  }
}

final Suggestor suggestor = BibleSuggestor();
