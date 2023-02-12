import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'deck.dart';
import 'string_utils.dart';

enum Hymnal { neh }

@immutable
class HymnParams {
  final Hymnal hymnal;
  final int number;
  final int linesPerMinorChunk;

  const HymnParams({
    this.hymnal = Hymnal.neh,
    this.number = 0,
    this.linesPerMinorChunk = 2,
  });

  HymnParams withHymnal(Hymnal hymnal) => HymnParams(
        hymnal: hymnal,
        number: number,
        linesPerMinorChunk: linesPerMinorChunk,
      );
  HymnParams withNumber(int number) => HymnParams(
        hymnal: hymnal,
        number: number,
        linesPerMinorChunk: linesPerMinorChunk,
      );
  HymnParams withLinesPerMinorChunk(int linesPerMinorChunk) => HymnParams(
        hymnal: hymnal,
        number: number,
        linesPerMinorChunk: linesPerMinorChunk,
      );
}

Future<http.Response?> _fetchHTML(HymnParams params) async {
  switch (params.hymnal) {
    case Hymnal.neh:
      final response1 = await http.get(
        Uri.parse('https://hymnary.org/hymn/NEH1985/${params.number}'),
      );
      if (response1.statusCode == 200) {
        return response1;
      }
      final response2 = await http.get(
        Uri.parse('https://hymnary.org/hymn/NEH1985/${params.number}a'),
      );
      if (response2.statusCode == 200) {
        return response2;
      }
  }
  return null;
}

Future<BuiltList<Chunk>?> fetchHymn(HymnParams params) async {
  final response = await _fetchHTML(params);
  if (response == null) {
    return null;
  }
  final body = html.parse(response.bodyBytes);

  final title = RegExp(r'^[^ ]* (.*)$')
          .firstMatch(
            body.getElementsByClassName('hymntitle').firstOrNull?.text ?? '0 ',
          )
          ?.group(1) ??
      '';

  final author = body
          .getElementsByClassName('result-row')
          .firstWhereOrNull((element) => element.text.contains('Author'))
          ?.getElementsByClassName('hy_infoItem')
          .first
          .text ??
      '';

  final text = body.getElementById('text');
  if (text == null) {
    return null;
  }
  final verses = text.children.map(
    (verse) => BodyChunk(
      minorChunks: verse.nodes
          .where((line) => line.nodeType == html.Node.TEXT_NODE)
          .map((line) => line.text?.trimLeadingInteger())
          .whereNotNull()
          .where(RegExp(r'[^\s]').hasMatch)
          .slices(params.linesPerMinorChunk)
          .map((lines) => lines.join('\n'))
          .toBuiltList(),
    ),
  );

  return [TitleChunk(title: title, subtitle: author), ...verses].toBuiltList();
}
