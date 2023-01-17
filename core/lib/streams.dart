import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'deck.dart';
import 'message.dart';
import 'map_stream_sink.dart';
import 'multiplex_stream.dart';

class ClientStreams {
  final StreamSink<void> requestUpdateStreamSink;
  final Stream<Programme> updateStream;
  final StreamSink<Programme> updateStreamSink;
  final Stream<Message> liveStream;
  final StreamSink<Message> liveStreamSink;

  void Function() dispose;

  ClientStreams._byParts({
    required this.requestUpdateStreamSink,
    required this.updateStream,
    required this.updateStreamSink,
    required this.liveStream,
    required this.liveStreamSink,
    required this.dispose,
  });

  factory ClientStreams.local() {
    final requestUpdateStream = StreamController<void>();
    final updateStream = StreamController<Programme>.broadcast();
    final liveStream = StreamController<Message>.broadcast();

    var programme = Programme.new_();
    Message liveMessage = CloseMessage();

    final requestUpdateStreamSubscription =
        requestUpdateStream.stream.listen((_) {
      updateStream.add(programme);
      liveStream.add(liveMessage);
    });
    final updateStreamSubscription =
        updateStream.stream.listen((Programme newProgramme) {
      programme = newProgramme;
    });
    final liveStreamSubscription = liveStream.stream.listen((Message message) {
      liveMessage = message;
    });

    dispose() {
      liveStreamSubscription.cancel();
      updateStreamSubscription.cancel();
      requestUpdateStreamSubscription.cancel();

      liveStream.close();
      updateStream.close();
      requestUpdateStream.close();
    }

    return ClientStreams._byParts(
      requestUpdateStreamSink: requestUpdateStream.sink,
      updateStream: updateStream.stream,
      updateStreamSink: updateStream.sink,
      liveStream: liveStream.stream,
      liveStreamSink: liveStream.sink,
      dispose: dispose,
    );
  }

  factory ClientStreams.websocket(WebSocketChannel webSocketChannel) {
    final multiplexStream = MultiplexStream(webSocketChannel.stream);
    final multiplexStreamSink = MultiplexStreamSink(webSocketChannel.sink);

    return ClientStreams._byParts(
      requestUpdateStreamSink: multiplexStreamSink['requestUpdate'],
      updateStream: multiplexStream['update']
          .map((event) => event as Map<String, dynamic>)
          .map(Programme.fromJson)
          .asBroadcastStream(),
      updateStreamSink:
          multiplexStreamSink['update'].map((programme) => programme.toJson()),
      liveStream: multiplexStream['live']
          .map((event) => event as Map<String, dynamic>)
          .map(Message.fromJson)
          .asBroadcastStream(),
      liveStreamSink:
          multiplexStreamSink['live'].map((message) => message.toJson()),
      dispose: () {},
    );
  }
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
