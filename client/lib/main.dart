import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:core/deck.dart';
import 'package:core/streams.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'global_settings_panel.dart';
import 'left_tabs.dart';
import 'live_panel.dart';
import 'open_save.dart';
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
  createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // final streams = ClientStreams.local();
  final streams = ClientStreams.websocket(
    WebSocketChannel.connect(
      Uri.parse("ws://127.0.0.1:8080/ws"),
    ),
  );

  final previewStream = StreamController<DeckKey?>.broadcast();

  var programme = Programme.new_();
  late final StreamSubscription<Programme> updateStreamSubscription;

  @override
  void initState() {
    super.initState();

    updateStreamSubscription = streams.updateStream.listen(
      (newProgramme) => setState(() => programme = newProgramme),
    );

    streams.requestUpdateStreamSink.add(null);
  }

  @override
  void dispose() {
    updateStreamSubscription.cancel();
    previewStream.close();
    streams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LeftTabs(
          keepHiddenChildrenAlive: true,
          children: [
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
          ],
        ).expanded(),
        const VerticalDivider(
          width: 5,
          thickness: 5,
          color: CupertinoColors.darkBackgroundGray,
        ),
        PreviewPanel(
          requestUpdateStreamSink: streams.requestUpdateStreamSink,
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
          requestUpdateStreamSink: streams.requestUpdateStreamSink,
          stream: streams.liveStream,
          streamSink: streams.liveStreamSink,
        ).expanded(),
      ],
    ).callbackShortcuts(bindings: {
      SingleActivator(
        LogicalKeyboardKey.keyN,
        control: !(Platform.isMacOS || Platform.isIOS),
        meta: Platform.isMacOS || Platform.isIOS,
      ): () => streams.updateStreamSink.add(Programme.new_()),
      SingleActivator(
        LogicalKeyboardKey.keyO,
        control: !(Platform.isMacOS || Platform.isIOS),
        meta: Platform.isMacOS || Platform.isIOS,
      ): () async {
        var newProgramme = await open();
        if (newProgramme != null) {
          streams.updateStreamSink.add(newProgramme);
        }
      },
      SingleActivator(
        LogicalKeyboardKey.keyS,
        control: !(Platform.isMacOS || Platform.isIOS),
        meta: Platform.isMacOS || Platform.isIOS,
      ): () => save(programme),
    });
  }
}
