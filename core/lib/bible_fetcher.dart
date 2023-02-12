import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'deck.dart';

@immutable
class BibleParams {
  final String version;
  final String query;

  const BibleParams({
    this.version = 'NRSVA',
    this.query = 'Job 3:2',
  });

  BibleParams withVersion(String version) => BibleParams(
        version: version,
        query: query,
      );
  BibleParams withQuery(String query) => BibleParams(
        version: version,
        query: query,
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
                  return !element.className.contains('versenum') &&
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

  return [
    TitleChunk(title: params.query, subtitle: params.version),
    BodyChunk(minorChunks: paragraphs.toBuiltList()),
  ].toBuiltList();
}
