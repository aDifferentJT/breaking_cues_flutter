import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart' as collection;

extension IterableUtils<T> on Iterable<T> {
  BuiltMap<U, BuiltList<T>> groupBy<U>(U Function(T) getKey) {
    return BuiltMap.build((builder) {
      for (final y in this) {
        builder.updateValue(
          getKey(y),
          (values) => values.rebuild((builder) => builder.add(y)),
          ifAbsent: () => BuiltList([y]),
        );
      }
    });
  }

  T? minBy<S>(S Function(T) orderBy, {int Function(S, S)? compare}) =>
      collection.minBy(this, orderBy, compare: compare);

  T? maxBy<S>(S Function(T) orderBy, {int Function(S, S)? compare}) =>
      collection.maxBy(this, orderBy, compare: compare);
}

extension ListUtils<T> on List<T> {
  List<T> safeSublist(int start, [int? end]) =>
      sublist(max(start, 0), end == null ? null : min(end, length));
}

extension BuiltListUtils<T> on BuiltList<T> {
  BuiltList<T> safeSublist(int start, [int? end]) =>
      sublist(max(start, 0), end == null ? null : min(end, length));
}
