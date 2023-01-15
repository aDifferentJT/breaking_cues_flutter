import 'dart:collection';

class IotaIterator extends Iterator<int> {
  IotaIterator({required int begin, this.end}) : x = begin - 1;

  int x = -1;
  final int? end;

  @override
  get current => x;

  @override
  bool moveNext() {
    x += 1;
    return end == null || x < end!;
  }
}

class IotaIterable extends IterableBase<int> {
  IotaIterable({this.begin = 0, this.end});

  int begin;
  int? end;

  @override
  Iterator<int> get iterator => IotaIterator(begin: begin, end: end);
}
