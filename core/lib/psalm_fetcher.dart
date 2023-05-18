import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'deck.dart';
import 'iterable_utils.dart';
import 'string_utils.dart';

enum Psalter { bcp, cw }

enum PsalmBold { none, oddVerses, secondHalf }

@immutable
class PsalmParams {
  final Psalter psalter;
  final int number;
  final int startVerse;
  final int endVerse;
  final bool gloria;
  final int versesPerMinorChunk;
  final int minorChunksPerMajorChunk;
  final PsalmBold bold;

  const PsalmParams()
      : psalter = Psalter.bcp,
        number = 1,
        startVerse = 1,
        endVerse = 176,
        gloria = false,
        versesPerMinorChunk = 1,
        minorChunksPerMajorChunk = 2,
        bold = PsalmBold.none;

  const PsalmParams._byParts({
    required this.psalter,
    required this.number,
    required this.startVerse,
    required this.endVerse,
    required this.gloria,
    required this.versesPerMinorChunk,
    required this.minorChunksPerMajorChunk,
    required this.bold,
  });

  PsalmParams withPsalter(Psalter psalter) => PsalmParams._byParts(
        psalter: psalter,
        number: number,
        startVerse: startVerse,
        endVerse: endVerse,
        gloria: gloria,
        versesPerMinorChunk: versesPerMinorChunk,
        minorChunksPerMajorChunk: minorChunksPerMajorChunk,
        bold: bold,
      );
  PsalmParams withNumber(int number) => PsalmParams._byParts(
        psalter: psalter,
        number: number,
        startVerse: startVerse,
        endVerse: endVerse,
        gloria: gloria,
        versesPerMinorChunk: versesPerMinorChunk,
        minorChunksPerMajorChunk: minorChunksPerMajorChunk,
        bold: bold,
      );
  PsalmParams withStartVerse(int startVerse) => PsalmParams._byParts(
        psalter: psalter,
        number: number,
        startVerse: startVerse,
        endVerse: endVerse,
        gloria: gloria,
        versesPerMinorChunk: versesPerMinorChunk,
        minorChunksPerMajorChunk: minorChunksPerMajorChunk,
        bold: bold,
      );
  PsalmParams withEndVerse(int endVerse) => PsalmParams._byParts(
        psalter: psalter,
        number: number,
        startVerse: startVerse,
        endVerse: endVerse,
        gloria: gloria,
        versesPerMinorChunk: versesPerMinorChunk,
        minorChunksPerMajorChunk: minorChunksPerMajorChunk,
        bold: bold,
      );
  PsalmParams withGloria(bool gloria) => PsalmParams._byParts(
        psalter: psalter,
        number: number,
        startVerse: startVerse,
        endVerse: endVerse,
        gloria: gloria,
        versesPerMinorChunk: versesPerMinorChunk,
        minorChunksPerMajorChunk: minorChunksPerMajorChunk,
        bold: bold,
      );
  PsalmParams withVersesPerMinorChunk(int versesPerMinorChunk) =>
      PsalmParams._byParts(
        psalter: psalter,
        number: number,
        startVerse: startVerse,
        endVerse: endVerse,
        gloria: gloria,
        versesPerMinorChunk: versesPerMinorChunk,
        minorChunksPerMajorChunk: minorChunksPerMajorChunk,
        bold: bold,
      );
  PsalmParams withMinorChunksPerMajorChunk(int minorChunksPerMajorChunk) =>
      PsalmParams._byParts(
        psalter: psalter,
        number: number,
        startVerse: startVerse,
        endVerse: endVerse,
        gloria: gloria,
        versesPerMinorChunk: versesPerMinorChunk,
        minorChunksPerMajorChunk: minorChunksPerMajorChunk,
        bold: bold,
      );
  PsalmParams withBold(PsalmBold bold) => PsalmParams._byParts(
        psalter: psalter,
        number: number,
        startVerse: startVerse,
        endVerse: endVerse,
        gloria: gloria,
        versesPerMinorChunk: versesPerMinorChunk,
        minorChunksPerMajorChunk: minorChunksPerMajorChunk,
        bold: bold,
      );
}

Future<BuiltList<Chunk>?> fetchPsalm(PsalmParams params) async {
  final String title;
  if (params.startVerse == PsalmParams().startVerse &&
      params.endVerse == PsalmParams().endVerse) {
    title = 'Psalm ${params.number}';
  } else if (params.endVerse == PsalmParams().endVerse) {
    title = 'Psalm ${params.number}: ${params.startVerse}-end';
  } else {
    title = 'Psalm ${params.number}: ${params.startVerse}-${params.endVerse}';
  }
  switch (params.psalter) {
    case Psalter.bcp:
      final response = await http.get(
        Uri.parse(
          'https://www.rmjs.co.uk/psalter/psalms.php?p=${params.number}',
        ),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final body = html.parse(response.bodyBytes);

      final verses = body
          .getElementsByClassName('psalm_body')
          .expand((element) => element.getElementsByTagName('li'))
          .map((element) => element.text)
          .whereNotNull()
          .map((verse) => verse
              .split(': ')
              .mapIndexed(
                (index, element) =>
                    params.bold == PsalmBold.secondHalf && index % 2 == 1
                        ? '*$element*'
                        : element,
              )
              .join(':\n'))
          .mapIndexed(
            (index, element) =>
                params.bold == PsalmBold.oddVerses && index % 2 == 1
                    ? '*$element*'
                    : element,
          )
          .toBuiltList()
          .safeSublist(params.startVerse - 1, params.endVerse)
          .slices(params.versesPerMinorChunk)
          .map((lines) => lines.join('\n'))
          .slices(params.minorChunksPerMajorChunk)
          .map((minorChunks) =>
              BodyChunk(minorChunks: minorChunks.toBuiltList()))
          .toBuiltList();

      return [
        TitleChunk(
          title: title,
          subtitle: 'Book of Common Prayer, Crown Copyright',
        ),
        ...verses,
        if (params.gloria)
          BodyChunk(
            minorChunks: (params.versesPerMinorChunk > 1
                    ? [
                        'Glory be to the Father, and to the Son,\n'
                            'and to the Holy Ghost;\n'
                            'As it was in the beginning, is now,\n'
                            'and ever shall be, world without end. Amen.',
                      ]
                    : [
                        'Glory be to the Father, and to the Son,\n'
                            'and to the Holy Ghost;',
                        'As it was in the beginning, is now,\n'
                            'and ever shall be, world without end. Amen.',
                      ])
                .map(
                  (minorChunk) => params.bold == PsalmBold.none
                      ? minorChunk
                      : '*$minorChunk*',
                )
                .toBuiltList(),
          ),
      ].toBuiltList();

    case Psalter.cw:
      final response = await http.get(
        Uri.parse(
          'https://www.churchofengland.org/prayer-and-worship/worship-texts-and-resources/common-worship/common-material/psalter/psalm-${params.number}',
        ),
      );
      if (response.statusCode != 200) {
        return null;
      }
      final body = html.parse(response.bodyBytes);

      final verses = body
          .getElementsByClassName('cw')
          .expand((element) => element.children)
          .where((element) => element.className.contains('ve'))
          .splitBefore((element) => element.className.contains('ve1'))
          .map(
            (elements) => elements
                .splitBefore(
                  (element) => element.className.contains('vein indent1'),
                )
                .map(
                  (elements) => elements
                      .map((element) => element.text.trimLeadingInteger())
                      .join('\n'),
                )
                .mapIndexed(
                  (index, element) =>
                      params.bold == PsalmBold.secondHalf && index % 2 == 1
                          ? '*$element*'
                          : element,
                )
                .join('\n'),
          )
          .mapIndexed(
            (index, element) =>
                params.bold == PsalmBold.oddVerses && index % 2 == 1
                    ? '*$element*'
                    : element,
          )
          .toBuiltList()
          .safeSublist(params.startVerse - 1, params.endVerse)
          .slices(params.versesPerMinorChunk)
          .map((lines) => lines.join('\n'))
          .slices(params.minorChunksPerMajorChunk)
          .map((minorChunks) =>
              BodyChunk(minorChunks: minorChunks.toBuiltList()))
          .toBuiltList();

      return [
        TitleChunk(
          title: title,
          subtitle: "Common Worship © The Archbishops' Council 2000",
        ),
        ...verses,
        if (params.gloria)
          BodyChunk(
            minorChunks: (params.versesPerMinorChunk > 1
                    ? [
                        'Glory to the Father and to the Son\n'
                            'and to the Holy Spirit;\n'
                            'as it was in the beginning is now\n'
                            'and shall be for ever. Amen.',
                      ]
                    : [
                        'Glory to the Father and to the Son\n'
                            'and to the Holy Spirit;',
                        'as it was in the beginning is now\n'
                            'and shall be for ever. Amen.',
                      ])
                .map(
                  (minorChunk) => params.bold == PsalmBold.none
                      ? minorChunk
                      : '*$minorChunk*',
                )
                .toBuiltList(),
          ),
      ].toBuiltList();
  }
}
