import 'dart:async';

class MapStreamSink<T, S> implements StreamSink<S> {
  final StreamSink<T> _wrapped;
  final T Function(S) _f;

  MapStreamSink(this._wrapped, this._f);

  @override
  void add(S event) => _wrapped.add(_f(event));

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _wrapped.addError(error, stackTrace);

  @override
  Future addStream(Stream<S> stream) => _wrapped.addStream(stream.map(_f));

  @override
  Future get done => _wrapped.done;

  @override
  Future close() => _wrapped.close();
}

extension MapStreamSinkExtension<T> on StreamSink<T> {
  StreamSink<S> map<S>(T Function(S) f) => MapStreamSink(this, f);
}
