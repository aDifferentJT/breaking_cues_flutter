import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/media_library.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';

import 'streams.dart';

void runServer(FutureOr<Response> Function(Request) outputHandler) async {
  final ip = InternetAddress.anyIPv4;

  final serverStreams = LocalClientStreams();

  final wsHandler = webSocketHandler((webSocket) {
    WebsocketServerStreams(
      webSocketChannel: webSocket,
      serverStreams: serverStreams,
    );
  });

  final mediaLibrary = MediaLibrary();

  FutureOr<Response> mediaHandler(Request request) {
    if (request.url == 'media') {
      final uuid = request.params['uuid'];
      if (uuid != null) {
        switch (request.method) {
          case 'GET':
            final media = mediaLibrary[UuidValue.fromString(uuid)];
            if (media != null) {
              return Response.ok(media);
            } else {
              return Response.notFound(null);
            }
          case 'PUT':
            return request
                .read()
                .fold(
                  Uint8List(0),
                  (previous, element) => previous..addAll(element),
                )
                .then(Media.fromBytes)
                .then(mediaLibrary.insert)
                .then((_) => Response.ok(null));
          default:
            return Response.badRequest();
        }
      } else {
        return Response.badRequest();
      }
    } else {
      return Response.notFound(null);
    }
  }

  final cascade = Cascade().add(wsHandler).add(mediaHandler).add(outputHandler);

  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(cascade.handler);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Breaking Cues Server listening on port ${server.port}');
}
