import 'dart:async';

import 'package:client/global_settings_panel.dart';
import 'package:client/left_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:core/deck.dart';
import 'package:core/streams.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'live_panel.dart';
import 'programme_panel.dart';
import 'preview_panel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Scaffold(body: MyHomePage()),
      theme: ThemeData.dark(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  // final streams = ClientStreams.local();
  final streams = ClientStreams.websocket(
    WebSocketChannel.connect(
      Uri.parse("ws://127.0.0.1:8080/ws"),
    ),
  );

  final previewStream = StreamController<DeckKey?>.broadcast();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    streams.dispose();

    previewStream.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LeftTabs(children: [
          TabEntry(
            icon: const Text('Programme').rotated(quarterTurns: 1),
            body: ProgrammePanel(
              updateStream: streams.updateStream,
              updateStreamSink: streams.updateStreamSink,
              previewStream: previewStream.stream,
              previewStreamSink: previewStream.sink,
              liveStream: streams.liveStream,
              liveStreamSink: streams.liveStreamSink,
            ),
          ),
          TabEntry(
            icon: const Text('Settings').rotated(quarterTurns: 1),
            body: GlobalSettingsPanel(
              updateStream: streams.updateStream,
              updateStreamSink: streams.updateStreamSink,
            ),
          ),
        ]).expanded(),
        const VerticalDivider(
          width: 5,
          thickness: 5,
          color: CupertinoColors.darkBackgroundGray,
        ),
        PreviewPanel(
          requestUpdateStream: streams.requestUpdateStreamSink,
          updateStream: streams.updateStream,
          updateStreamSink: streams.updateStreamSink,
          previewStream: previewStream.stream,
          liveStreamSink: streams.liveStreamSink,
        ).expanded(),
        const VerticalDivider(
          width: 5,
          thickness: 5,
          color: CupertinoColors.darkBackgroundGray,
        ),
        LivePanel(
          stream: streams.liveStream,
          streamSink: streams.liveStreamSink,
        ).expanded(),
      ],
    );
  }
}