import 'dart:math';

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
        minorChunksPerMajorChunk = 1,
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

@immutable
abstract class BCPPsalmPage {
  final Uri url;

  static BCPPsalmPage? parse(String title, Uri url) {
    if (RegExp(r'Psalm 119: ([0-9]+) - ([0-9]+)').matchAsPrefix(title)
        case final match?) {
      final start = int.parse(match[1]!);
      final end = int.parse(match[2]!);
      return BCPPsalm119Page(start, end, url);
    } else if (RegExp(r'Psalm ([0-9]+)').matchAsPrefix(title)
        case final match?) {
      final number = int.parse(match[1]!);
      return BCPPsalmNot119Page(number, number, url);
    } else if (RegExp(r'Psalms ([0-9]+) - ([0-9]+)').matchAsPrefix(title)
        case final match?) {
      final start = int.parse(match[1]!);
      final end = int.parse(match[2]!);
      return BCPPsalmNot119Page(start, end, url);
    } else {
      return null;
    }
  }

  BCPPsalmPage.withURL(this.url);

  bool overlaps(PsalmParams params);

  Iterable<T> selectVerses<T>(BuiltList<T> verses, PsalmParams params);
}

@immutable
class BCPPsalmNot119Page extends BCPPsalmPage {
  final int start;
  final int end;

  BCPPsalmNot119Page(this.start, this.end, Uri url) : super.withURL(url);

  bool overlaps(PsalmParams params) {
    return this.start <= params.number && params.number <= this.end;
  }

  Iterable<T> selectVerses<T>(BuiltList<T> verses, PsalmParams params) {
    return verses.safeSublist(params.startVerse - 1, params.endVerse);
  }
}

@immutable
class BCPPsalm119Page extends BCPPsalmPage {
  final int startVerse;
  final int endVerse;

  BCPPsalm119Page(this.startVerse, this.endVerse, Uri url) : super.withURL(url);

  bool overlaps(final PsalmParams params) {
    return params.number == 119 &&
        params.startVerse <= this.endVerse &&
        this.startVerse <= params.endVerse;
  }

  Iterable<T> selectVerses<T>(BuiltList<T> verses, PsalmParams params) {
    return verses.safeSublist(
        max(params.startVerse, this.startVerse) - this.startVerse,
        min(params.endVerse, this.endVerse) - this.startVerse);
  }
}

@immutable
class PsalmPageWithResponse {
  final BCPPsalmPage page;
  final http.Response response;

  PsalmPageWithResponse(this.page, this.response);
}

class CannotFetchPsalm {}

Future<BuiltList<Chunk>?> fetchPsalm(PsalmParams params) async {
  try {
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
        final psalterContentsResponse = await http.get(
          Uri.parse(
            'https://www.churchofengland.org/prayer-and-worship/worship-texts-and-resources/book-common-prayer/psalter',
          ),
        );
        if (psalterContentsResponse.statusCode != 200) {
          throw CannotFetchPsalm();
        }
        final psalterContentsBody =
            html.parse(psalterContentsResponse.bodyBytes);

        final psalmPages = psalterContentsBody
            .getElementsByClassName('prayerContainer')
            .expand((element) => element.children)
            .where((element) => element.className != 'vlcopyright')
            .expand((element) => element.getElementsByTagName('a'))
            .map((element) {
          final title = element.attributes['title'];
          final urlString = element.attributes['href'];
          final url = urlString != null
              ? Uri.tryParse('https://www.churchofengland.org$urlString')
              : null;
          final page = title != null && url != null
              ? BCPPsalmPage.parse(title, url)
              : null;
          if (page != null) {
            return page.overlaps(params) ? page : null;
          } else {
            throw CannotFetchPsalm();
          }
        }).whereNotNull();

        final verses = (await Future.wait(psalmPages.map((page) async {
          final response = await http.get(page.url);
          if (response.statusCode != 200) {
            throw CannotFetchPsalm();
          }
          final body = html.parse(response.bodyBytes);

          final verses1 = body
              .getElementsByClassName('prayerContainer')
              .expand((element) => element.children);

          final verses2 = params.number == 119
              ? verses1
              : verses1
                  .splitBefore(
                      (element) => element.className == 'vlitemheading')
                  .skip(1)
                  .where((elements) => elements.length > 0)
                  .firstWhere(
                      (elements) =>
                          elements.first.text == 'Psalm ${params.number}.',
                      orElse: () => throw CannotFetchPsalm());

          final verses3 = verses2
              .where((element) => element.className == 'vlpsalm')
              .map((element) {
                element
                    .getElementsByClassName('vlversenumber')
                    .forEach((element) => element.remove());
                return element.text.trim();
              })
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
              .toBuiltList();

          return page.selectVerses(verses3, params);
        })))
            .expand((verses) => verses)
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
          throw CannotFetchPsalm();
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
  } on CannotFetchPsalm {
    return null;
  }
}
