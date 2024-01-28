import 'package:core/pubsub.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'deck.dart';
import 'message.dart';
import 'map_stream_sink.dart';
import 'multiplex_stream.dart';

@immutable
class Update {
  final Programme programme;
  final UuidValue? source;

  Update({required this.programme, this.source});

  Update.fromJson(Map<String, dynamic> json)
      : programme = Programme.fromJson(
          json['programme'] as Map<String, dynamic>,
        ),
        source = (() {
          switch (json['source'] as String?) {
            case null:
              return null;
            case final source:
              return UuidValue.fromString(source);
          }
        })();

  Map<String, dynamic> toJson() => {
        'programme': programme.toJson(),
        'source': source?.toString(),
      };
}

abstract class ClientStreams {
  PubSub<Update> get update;
  PubSub<Message> get live;

  void dispose();
}

class LocalClientStreams extends ClientStreams {
  final PubSubController<Update> update =
      PubSubController(initialValue: Update(programme: Programme.new_()));
  final PubSubController<Message> live =
      PubSubController<Message>(initialValue: CloseMessage());

  LocalClientStreams();

  dispose() {
    update.dispose();
    live.dispose();
  }
}

class WebsocketClientStreams extends ClientStreams {
  final WebSocketChannel websocketChannel;

  @override
  final PubSubStreamsClient<Update> update;
  @override
  final PubSubStreamsClient<Message> live;

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
  })  : update = PubSubStreamsClient(
          sink: multiplexStreamSink['update'].map((update) => update.toJson()),
          stream: multiplexStream['update']
              .map((update) => update as Map<String, dynamic>)
              .map(Update.fromJson)
              .asBroadcastStream(),
          requestUpdate:
              multiplexStreamSink['updateRequestUpdate'].map((_) => null),
        ),
        live = PubSubStreamsClient(
          sink: multiplexStreamSink['live'].map((message) => message.toJson()),
          stream: multiplexStream['live']
              .map((message) => message as Map<String, dynamic>)
              .map(Message.fromJson)
              .asBroadcastStream(),
          requestUpdate:
              multiplexStreamSink['liveRequestUpdate'].map((_) => null),
        );

  @override
  void dispose() {}
}

class WebsocketServerStreams {
  late final PubSubStreamsServer<Update> update;
  late final PubSubStreamsServer<Message> liveStream;

  WebsocketServerStreams({
    required WebSocketChannel webSocketChannel,
    required ClientStreams serverStreams,
  }) {
    final multiplexStream = MultiplexStream(webSocketChannel.stream);
    final multiplexStreamSink = MultiplexStreamSink(webSocketChannel.sink);

    update = serverStreams.update.streamsServer(
      sink: multiplexStreamSink['update'].map((update) => update.toJson()),
      stream: multiplexStream['update']
          .map((event) => event as Map<String, dynamic>)
          .map(Update.fromJson),
      requestUpdate: multiplexStream['updateRequestUpdate'],
    );

    liveStream = serverStreams.live.streamsServer(
      sink: multiplexStreamSink['live'].map((message) => message.toJson()),
      stream: multiplexStream['live']
          .map((event) => event as Map<String, dynamic>)
          .map(Message.fromJson),
      requestUpdate: multiplexStream['liveRequestUpdate'],
    );
  }
}
