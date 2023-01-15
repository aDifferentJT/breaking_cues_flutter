import 'dart:async';
import 'dart:convert';

import 'map_stream_sink.dart';

class MultiplexStream {
  final Stream _wrapped;
  final Map<String, StreamController> _streamControllers = {};

  MultiplexStream(this._wrapped) {
    _wrapped.listen(
      (event) {
        final data = jsonDecode(event);
        if (data is Map<String, dynamic>) {
          final controller = _streamControllers[data['key']];
          if (controller != null) {
            controller.add(data['event']);
          }
        }
      },
      onDone: () {
        for (final controller in _streamControllers.values) {
          controller.close();
        }
      },
    );
  }

  Stream operator [](String key) => _streamControllers
      .update(
        key,
        (streamController) => streamController,
        ifAbsent: () => StreamController.broadcast(),
      )
      .stream;
}

class MultiplexStreamSink {
  final StreamSink _wrapped;

  const MultiplexStreamSink(this._wrapped);

  StreamSink operator [](String key) =>
      _wrapped.map((event) => jsonEncode({'key': key, 'event': event}));
}
