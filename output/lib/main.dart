import 'package:core/streams.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'get_name.dart' if (dart.library.html) 'get_name_web.dart';
import 'output.dart';

void main() {
  final name = getName();

  runApp(_OutputApp(name: name));
}

class _OutputApp extends StatefulWidget {
  final String name;

  const _OutputApp({required this.name});

  @override
  createState() => _OutputAppState();
}

class _OutputAppState extends State<_OutputApp> {
  final streams = WebsocketClientStreams(
    WebSocketChannel.connect(
      Uri.parse('ws://${getHost()}'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ScaledOutput(
        pubSub: streams.live,
        name: widget.name,
      ),
    );
  }
}
