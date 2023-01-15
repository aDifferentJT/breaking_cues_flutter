import 'package:core/streams.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';

final serverStreams = ClientStreams.local();

Handler get onRequest {
  return webSocketHandler((channel, protocol) {
    websocketServerStreams(
      webSocketChannel: channel,
      serverStreams: serverStreams,
    );
  });
}
