import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:core/iterable_utils.dart';

@immutable
class Matcher {
  final bool _isValid;
  final BuiltMap<int, Matcher> _trie;

  Matcher(Iterable<String> options, {int index = 0})
      : this._grouped(options.groupBy((option) {
          if (option.length <= index) {
            return null;
          } else {
            return option.codeUnitAt(index);
          }
        }), index: index);

  Matcher._grouped(BuiltMap<int?, BuiltList<String>> options, {int index = 0})
      : _isValid = options.containsKey(null as Object),
        _trie = (options.rebuild((builder) => builder.remove(null))).map(
          (key, value) => MapEntry(key!, Matcher(value, index: index + 1)),
        );

  BuiltSet<String> _all(String prefix) {
    return BuiltSet.build((builder) {
      if (_isValid) {
        builder.add(prefix);
      }
      builder.addAll(_trie.entries.expand((entry) =>
          entry.value._all(prefix + String.fromCharCode(entry.key))));
    });
  }

  BuiltSet<String> match(String cue, {String prefix = "", int index = 0}) {
    if (cue.length <= index) {
      return _all(prefix);
    } else {
      final head = cue.codeUnitAt(index);
      return _trie[head]?.match(cue,
              prefix: prefix + String.fromCharCode(head), index: index + 1) ??
          BuiltSet();
    }
  }
}
