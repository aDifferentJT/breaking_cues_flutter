import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'deck.dart';
import 'message.dart';
import 'map_stream_sink.dart';
import 'multiplex_stream.dart';

abstract class ClientStreams {
  StreamSink<void> get requestUpdateStreamSink;
  Stream<Programme> get updateStream;
  StreamSink<Programme> get updateStreamSink;
  Stream<Message> get liveStream;
  StreamSink<Message> get liveStreamSink;

  void dispose();
}

class LocalClientStreams extends ClientStreams {
  var _programme = Programme.new_();
  Message _liveMessage = CloseMessage();

  final _requestUpdateStreamController = StreamController<void>();
  final _updateStreamController = StreamController<Programme>.broadcast();
  final _liveStreamController = StreamController<Message>.broadcast();

  late final StreamSubscription<void> _requestUpdateStreamSubscription;
  late final StreamSubscription<Programme> _updateStreamSubscription;
  late final StreamSubscription<Message> _liveStreamSubscription;

  @override
  StreamSink<void> get requestUpdateStreamSink =>
      _requestUpdateStreamController.sink;
  @override
  Stream<Programme> get updateStream => _updateStreamController.stream;
  @override
  StreamSink<Programme> get updateStreamSink => _updateStreamController.sink;
  @override
  Stream<Message> get liveStream => _liveStreamController.stream;
  @override
  StreamSink<Message> get liveStreamSink => _liveStreamController.sink;

  LocalClientStreams() {
    _requestUpdateStreamSubscription =
        _requestUpdateStreamController.stream.listen(
      (_) {
        _updateStreamController.add(_programme);
        _liveStreamController.add(_liveMessage);
      },
    );
    _updateStreamSubscription = _updateStreamController.stream.listen(
      (Programme newProgramme) {
        _programme = newProgramme;
      },
    );
    _liveStreamSubscription = _liveStreamController.stream.listen(
      (Message message) {
        _liveMessage = message;
      },
    );
  }

  dispose() {
    _liveStreamSubscription.cancel();
    _updateStreamSubscription.cancel();
    _requestUpdateStreamSubscription.cancel();

    _liveStreamController.close();
    _updateStreamController.close();
    _requestUpdateStreamController.close();
  }
}

class WebsocketClientStreams extends ClientStreams {
  final WebSocketChannel websocketChannel;
  @override
  final Stream<Message> liveStream;
  @override
  final StreamSink<Message> liveStreamSink;
  @override
  final StreamSink<void> requestUpdateStreamSink;
  @override
  final Stream<Programme> updateStream;
  @override
  final StreamSink<Programme> updateStreamSink;

  WebsocketClientStreams(WebSocketChannel webSocketChannel)
      : this._multiplexStream(
          websocketChannel: webSocketChannel,
          multiplexStream: MultiplexStream(webSocketChannel.stream),
          multiplexStreamSink: MultiplexStreamSink(webSocketChannel.sink),
        );

  WebsocketClientStreams._multiplexStream({
    required this.websocketChannel,
    required final MultiplexStream multiplexStream,
    required final MultiplexStreamSink multiplexStreamSink,
  })  : requestUpdateStreamSink = multiplexStreamSink['requestUpdate'],
        updateStream = multiplexStream['update']
            .map((event) => event as Map<String, dynamic>)
            .map(Programme.fromJson)
            .asBroadcastStream(),
        updateStreamSink = multiplexStreamSink['update']
            .map((programme) => programme.toJson()),
        liveStream = multiplexStream['live']
            .map((event) => event as Map<String, dynamic>)
            .map(Message.fromJson)
            .asBroadcastStream(),
        liveStreamSink =
            multiplexStreamSink['live'].map((message) => message.toJson());
  @override
  void dispose() {}
}

void websocketServerStreams({
  required WebSocketChannel webSocketChannel,
  required ClientStreams serverStreams,
}) {
  final multiplexStream = MultiplexStream(webSocketChannel.stream);
  final multiplexStreamSink = MultiplexStreamSink(webSocketChannel.sink);

  multiplexStream['requestUpdate']
      .listen(serverStreams.requestUpdateStreamSink.add);
  serverStreams.updateStream
      .map((document) => document.toJson())
      .listen(multiplexStreamSink['update'].add);
  multiplexStream['update']
      .map((event) => event as Map<String, dynamic>)
      .map(Programme.fromJson)
      .listen(serverStreams.updateStreamSink.add);
  serverStreams.liveStream
      .map((message) => message.toJson())
      .listen(multiplexStreamSink['live'].add);
  multiplexStream['live']
      .map((event) => event as Map<String, dynamic>)
      .map(Message.fromJson)
      .listen(serverStreams.liveStreamSink.add);
}
