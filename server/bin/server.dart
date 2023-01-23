import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'package:core/streams.dart';

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;

  final outputHandler = createStaticHandler(
    '../output/build/web',
    defaultDocument: 'index.html',
  );

  final serverStreams = ClientStreams.local();

  final wsHandler = webSocketHandler((webSocket) {
    websocketServerStreams(
      webSocketChannel: webSocket,
      serverStreams: serverStreams,
    );
  });

  final cascade = Cascade().add(wsHandler).add(outputHandler);

  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(cascade.handler);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Breaking Cues Server listening on port ${server.port}');
}
