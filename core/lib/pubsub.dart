import 'dart:async';

import 'package:core/map_stream_sink.dart';
import 'package:meta/meta.dart';

abstract class PubSub<T> {
  StreamSink<T> get sink;
  Stream<T> get stream;
  StreamSink<void> get requestUpdate;

  void dispose();

  void publish(T value) {
    sink.add(value);
  }

  StreamSubscription<T> subscribe(void Function(T event)? onData) {
    final subscription = stream.listen(onData);
    requestUpdate.add(());
    return subscription;
  }

  PubSubStreamsServer<T> streamsServer({
    required final StreamSink<T> sink,
    required final Stream<T> stream,
    required final Stream<void> requestUpdate,
  }) =>
      PubSubStreamsServer(
        pubSub: this,
        sink: sink,
        stream: stream,
        requestUpdate: requestUpdate,
      );

  BorrowedPubSub<T> get borrowed => BorrowedPubSub(this);

  CachedPubSub<T> cached({void Function(T)? onUpdate}) => CachedPubSub(
        this,
        onUpdate: onUpdate,
      );

  MapPubSub<T, U> map<U>(U Function(T) down, T Function(U) up) =>
      MapPubSub(this, down, up);

  StatefulMapPubSub<T, U, S> statefulMap<U, S>(
    S state,
    (U, S) Function(T, S) down,
    (T, S) Function(U, S) up,
  ) =>
      StatefulMapPubSub(this, state, down, up);

  FilterUpwardNullsPubSub<T> get filterUpwardNulls =>
      FilterUpwardNullsPubSub(this);
}

extension OptionalPubSub<T> on PubSub<T?> {
  FilterDownwardNullsPubSub<T> get filterDownwardNulls =>
      FilterDownwardNullsPubSub(this);
}

@immutable
class PubSubStreamsClient<T> extends PubSub<T> {
  final StreamSink<T> sink;
  final Stream<T> stream;
  final StreamSink<void> requestUpdate;

  PubSubStreamsClient({
    required this.sink,
    required this.stream,
    required this.requestUpdate,
  });

  @override
  void dispose() {}
}

@immutable
class PubSubStreamsServer<T> {
  final StreamSubscription<T> _down;
  final StreamSubscription<T> _up;
  final StreamSubscription<void> _requestUpdate;

  PubSubStreamsServer({
    required PubSub<T> pubSub,
    required final StreamSink<T> sink,
    required final Stream<T> stream,
    required final Stream<void> requestUpdate,
  })  : _down = pubSub.stream.listen(sink.add),
        _up = stream.listen(pubSub.sink.add),
        _requestUpdate = requestUpdate.listen(pubSub.requestUpdate.add);

  void dispose() {
    _down.cancel();
    _up.cancel();
    _requestUpdate.cancel();
  }
}

class PubSubController<T> extends PubSub<T> {
  T _value;

  final _stream = StreamController<T>.broadcast();
  final _requestUpdate = StreamController<void>();

  late final StreamSubscription<T> _streamSubscription;
  late final StreamSubscription<void> _requestUpdateSubscription;

  PubSubController({required T initialValue}) : _value = initialValue {
    _streamSubscription = _stream.stream.listen(
      (value) => _value = value,
    );
    _requestUpdateSubscription = _requestUpdate.stream.listen(
      (_) => _stream.add(_value),
    );
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    _requestUpdateSubscription.cancel();
    _stream.close();
    _requestUpdate.close();
  }

  @override
  StreamSink<T> get sink => _stream.sink;

  @override
  Stream<T> get stream => _stream.stream;

  @override
  StreamSink<void> get requestUpdate => _requestUpdate.sink;
}

class BorrowedPubSub<T> extends PubSub<T> {
  PubSub<T> _pubSub;

  BorrowedPubSub(this._pubSub);

  @override
  void dispose() {}

  @override
  StreamSink<T> get sink => _pubSub.sink;

  @override
  Stream<T> get stream => _pubSub.stream;

  @override
  StreamSink<void> get requestUpdate => _pubSub.requestUpdate;
}

class CachedPubSub<T> extends PubSub<T> {
  PubSub<T> _pubSub;
  T? _value;
  void Function(T)? onUpdate;

  final _down = StreamController<T>.broadcast();
  final _up = StreamController<T>();
  final _requestUpdate = StreamController<void>();

  late final StreamSubscription<T> _downSubscription;
  late final StreamSubscription<T> _upSubscription;
  late final StreamSubscription<void> _requestUpdateSubscription;

  T? get value => _value;

  CachedPubSub(this._pubSub, {this.onUpdate}) {
    _downSubscription = _pubSub.subscribe((value) {
      _value = value;
      if (onUpdate != null) {
        onUpdate!(value);
      }
      _down.sink.add(value);
    });

    _upSubscription = _up.stream.listen((value) {
      if (_value != value) {
        _value = value;
        _pubSub.publish(value);
      }
    });

    _requestUpdateSubscription = _requestUpdate.stream.listen((_) {
      if (_value != null) {
        _pubSub.sink.add(_value!);
      }
    });
  }

  @override
  void dispose() {
    _downSubscription.cancel();
    _upSubscription.cancel();
    _requestUpdateSubscription.cancel();
    _pubSub.dispose();
  }

  @override
  StreamSink<T> get sink => _up.sink;

  @override
  Stream<T> get stream => _down.stream;

  @override
  StreamSink<void> get requestUpdate => _requestUpdate.sink;
}

class MapPubSub<T, U> extends PubSub<U> {
  PubSub<T> _pubSub;
  U Function(T) _down;
  T Function(U) _up;

  MapPubSub(this._pubSub, this._down, this._up);

  @override
  void dispose() {
    _pubSub.dispose();
  }

  @override
  StreamSink<U> get sink => _pubSub.sink.map(_up);

  @override
  Stream<U> get stream => _pubSub.stream.map(_down);

  @override
  StreamSink<void> get requestUpdate => _pubSub.requestUpdate;
}

class ZipPubSub<T, U> extends PubSub<(T, U)> {
  CachedPubSub<T> _x;
  CachedPubSub<U> _y;

  final _downController = StreamController<(T, U)>.broadcast();
  final _upController = StreamController<(T, U)>.broadcast();
  final _requestUpdateController = StreamController<void>.broadcast();

  late final StreamSubscription<(T, U)> _downSubscription;
  late final StreamSubscription<T> _xSubscription;
  late final StreamSubscription<U> _ySubscription;
  late final StreamSubscription<void> _requestUpdateSubscription;

  ZipPubSub(PubSub<T> x, PubSub<U> y)
      : _x = x.cached(),
        _y = y.cached() {
    _downSubscription = _downController.stream.listen((value) {
      final (x, y) = value;
      _x.sink.add(x);
      _y.sink.add(y);
    });

    _xSubscription = x.stream.listen((x) {
      if (_y.value != null) {
        _upController.sink.add((x, _y.value!));
      }
    });

    _ySubscription = y.stream.listen((y) {
      if (_x.value != null) {
        _upController.sink.add((_x.value!, y));
      }
    });

    _requestUpdateSubscription =
        _requestUpdateController.stream.listen((event) {
      _x.requestUpdate.add(());
      _y.requestUpdate.add(());
    });
  }

  void dispose() {
    _xSubscription.cancel();
    _ySubscription.cancel();
    _downSubscription.cancel();
    _requestUpdateSubscription.cancel();

    _downController.close();
    _upController.close();
    _requestUpdateController.close();

    _x.dispose();
    _y.dispose();
  }

  @override
  StreamSink<(T, U)> get sink => _downController.sink;

  @override
  Stream<(T, U)> get stream => _upController.stream;

  @override
  StreamSink<void> get requestUpdate => _requestUpdateController.sink;
}

class StatefulMapPubSub<T, U, S> extends PubSub<U> {
  PubSub<T> _pubSub;
  S _state;
  (U, S) Function(T, S) _down;
  (T, S) Function(U, S) _up;

  StatefulMapPubSub(this._pubSub, this._state, this._down, this._up);

  @override
  void dispose() {
    _pubSub.dispose();
  }

  @override
  StreamSink<void> get requestUpdate => _pubSub.requestUpdate;

  @override
  StreamSink<U> get sink => _pubSub.sink.map((value1) {
        final (value2, state) = _up(value1, _state);
        _state = state;
        return value2;
      });

  @override
  Stream<U> get stream => _pubSub.stream.map((value1) {
        final (value2, state) = _down(value1, _state);
        _state = state;
        return value2;
      });
}

class FilterDownwardNullsPubSub<T> extends PubSub<T> {
  PubSub<T?> _pubSub;

  FilterDownwardNullsPubSub(this._pubSub);

  @override
  void dispose() {
    _pubSub.dispose();
  }

  @override
  StreamSink<T> get sink => _pubSub.sink.map((x) => x);

  @override
  Stream<T> get stream => _pubSub.stream.where((x) => x != null).cast<T>();

  @override
  StreamSink<void> get requestUpdate => _pubSub.requestUpdate;
}

class FilterUpwardNullsPubSub<T> extends PubSub<T?> {
  PubSub<T> _pubSub;

  FilterUpwardNullsPubSub(this._pubSub);

  @override
  void dispose() {
    _pubSub.dispose();
  }

  @override
  StreamSink<T?> get sink => _pubSub.sink.where((x) => x != null);

  @override
  Stream<T?> get stream => _pubSub.stream;

  @override
  StreamSink<void> get requestUpdate => _pubSub.requestUpdate;
}
