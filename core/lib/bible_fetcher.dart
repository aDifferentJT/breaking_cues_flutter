import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'deck.dart';

enum BibleFraming { none, standard, gospel, lentGospel }

@immutable
class BibleParams {
  final String version;
  final String query;
  final BibleFraming framing;

  const BibleParams({
    this.version = 'NRSVA',
    this.query = 'Job 3:2',
    this.framing = BibleFraming.standard,
  });

  BibleParams withVersion(String version) => BibleParams(
        version: version,
        query: query,
        framing: framing,
      );
  BibleParams withQuery(String query) => BibleParams(
        version: version,
        query: query,
        framing: framing,
      );
  BibleParams withFraming(BibleFraming framing) => BibleParams(
        version: version,
        query: query,
        framing: framing,
      );
}

Future<BuiltList<Chunk>?> fetchBible(BibleParams params) async {
  final encodedQuery = Uri.encodeQueryComponent(
    params.query.replaceAll(
      RegExp('end', caseSensitive: false),
      '10000',
    ),
  );
  final encodedVersion = Uri.encodeQueryComponent(params.version);
  final response = await http.get(
    Uri.parse(
      'https://www.biblegateway.com/passage/?search=$encodedQuery&version=$encodedVersion&interface=print',
    ),
  );
  if (response.statusCode != 200) {
    return null;
  }
  final body = html.parse(response.bodyBytes);

  final paragraphs = body
      .getElementsByClassName('passage-content')
      .expand((element) => element.getElementsByTagName('p'))
      .map((element) => element
          .getElementsByClassName('text')
          .expand((element) => element.nodes)
          .where(
            (element) {
              if (element.nodeType == html.Node.TEXT_NODE) {
                return true;
              } else {
                if (element is html.Element) {
                  return !element.className.contains('chapternum') &&
                      !element.className.contains('versenum') &&
                      !element.className.contains('footnote');
                } else {
                  return true;
                }
              }
            },
          )
          .map((element) => element.text)
          .whereNotNull()
          .join(' ')
          .replaceAll(RegExp(r'\s+'), ' '));

  switch (params.framing) {
    case BibleFraming.none:
      return [
        TitleChunk(title: params.query, subtitle: params.version),
        BodyChunk(minorChunks: paragraphs.toBuiltList()),
      ].toBuiltList();
    case BibleFraming.standard:
      return [
        TitleChunk(title: params.query, subtitle: params.version),
        BodyChunk(minorChunks: paragraphs.toBuiltList()),
        BodyChunk(
          minorChunks: [
            'This is the word of the Lord.\n' '*Thanks be to God.*',
          ].toBuiltList(),
        ),
      ].toBuiltList();
    case BibleFraming.gospel:
      final gospelWriter =
          RegExp(r'[A-Za-z]+').matchAsPrefix(params.query)?.group(0) ?? 'N';
      return [
        TitleChunk(title: 'The Gospel', subtitle: ''),
        BodyChunk(
          minorChunks: [
            'Alleluia, alleluia.\nAlleluia, alleluia.',
            '*Alleluia, alleluia.\nAlleluia, alleluia.*',
          ].toBuiltList(),
        ),
        TitleChunk(title: 'Gospel Acclamation', subtitle: ''),
        BodyChunk(
          minorChunks: [
            '*Alleluia, alleluia.\nAlleluia, alleluia.*',
          ].toBuiltList(),
        ),
        BodyChunk(
          minorChunks: [
            'The Lord be with you\n' '*and also with you.*',
          ].toBuiltList(),
        ),
        BodyChunk(
          minorChunks: [
            'Hear the Gospel of our Lord Jesus Christ according to $gospelWriter.\n'
                '*Glory to you, O Lord.*',
          ].toBuiltList(),
        ),
        TitleChunk(title: params.query, subtitle: params.version),
        BodyChunk(minorChunks: paragraphs.toBuiltList()),
        BodyChunk(
          minorChunks: [
            'This is the Gospel of the Lord.\n' '*Praise to you, O Christ.*',
          ].toBuiltList(),
        ),
      ].toBuiltList();
    case BibleFraming.lentGospel:
      final gospelWriter =
          RegExp(r'[A-Za-z]+').matchAsPrefix(params.query)?.group(0) ?? 'N';
      return [
        TitleChunk(title: 'The Gospel', subtitle: ''),
        BodyChunk(
          minorChunks: [
            'Praise to you, O Christ,\nking of eternal glory!.',
            '*Praise to you, O Christ,\nking of eternal glory!.*',
          ].toBuiltList(),
        ),
        TitleChunk(title: 'Gospel Acclamation', subtitle: ''),
        BodyChunk(
          minorChunks: [
            '*Praise to you, O Christ,\nking of eternal glory!.*',
          ].toBuiltList(),
        ),
        BodyChunk(
          minorChunks: [
            'The Lord be with you\n' '*and also with you.*',
          ].toBuiltList(),
        ),
        BodyChunk(
          minorChunks: [
            'Hear the Gospel of our Lord Jesus Christ according to $gospelWriter.\n'
                '*Glory to you, O Lord.*',
          ].toBuiltList(),
        ),
        TitleChunk(title: params.query, subtitle: params.version),
        BodyChunk(minorChunks: paragraphs.toBuiltList()),
        BodyChunk(
          minorChunks: [
            'This is the Gospel of the Lord.\n' '*Praise to you, O Christ.*',
          ].toBuiltList(),
        ),
      ].toBuiltList();
  }
}
