import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:output/music.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:core/deck.dart';
import 'package:core/server.dart';
import 'package:core/streams.dart';
import 'package:flutter_utils/widget_modifiers.dart';
import 'package:mime/mime.dart';

import 'package:shelf/shelf.dart';

import 'client_settings_panel.dart';
import 'colours.dart';
import 'output_settings_panel.dart';
import 'left_tabs.dart';
import 'live_panel.dart';
import 'open_save.dart';
import 'programme_panel.dart';
import 'preview_panel.dart';

FutureOr<Response> outputHandler(Request request) {
  final path = switch (request.url.path) {
    '' => 'index.html',
    final path => path,
  };
  if (path.contains('..')) {
    return Response.forbidden(null);
  }
  final contentType = MimeTypeResolver().lookup(path);
  return rootBundle.loadString('output/$path').then(
      (file) => Response.ok(request.method == 'HEAD' ? null : file, headers: {
            if (contentType != null) HttpHeaders.contentTypeHeader: contentType,
            HttpHeaders.contentLengthHeader: '${file.length}',
          }),
      onError: (error) => Response.notFound(null));
}

void main() async {
  runServer(outputHandler);
  runApp(const ClientApp());
}

class ClientApp extends StatefulWidget {
  const ClientApp({super.key});

  @override
  createState() => _ClientAppState();
}

class _ClientAppState extends State<ClientApp>
    with SingleTickerProviderStateMixin {
  var programme = Programme.new_();
  StreamSubscription<Programme>? updateStreamSubscription;

  void subscribeToUpdateStream() {
    updateStreamSubscription?.cancel();
    updateStreamSubscription = streams.updateStream.listen(
      (newProgramme) => programme = newProgramme,
    );

    streams.requestUpdateStreamSink.add(null);
  }

  String serverAddress = "ws://127.0.0.1:8080";
  StreamSubscription<void>? onConnect;
  WebsocketClientStreams? remoteStreams;

  void disconnect() {
    onConnect?.cancel();
    setState(() => remoteStreams = null);
    subscribeToUpdateStream();
  }

  void connect() async {
    disconnect();
    final uri = Uri.tryParse(serverAddress);
    if (uri != null) {
      try {
        final webSocketChannel = WebSocketChannel.connect(uri);
        await webSocketChannel.ready;
        setState(
          () => remoteStreams = WebsocketClientStreams(webSocketChannel),
        );
        subscribeToUpdateStream();
      } catch (e) {
        print('Error! can not connect WS connectWs $e');
      }
    }
  }

  bool get connected => remoteStreams != null;

  final localStreams = LocalClientStreams();
  ClientStreams get streams => remoteStreams ?? localStreams;

  final previewStream = StreamController<DeckKey?>.broadcast();

  late final AnimationController colourPaletteController;
  Animatable<ColourPalette> colourPalette =
      ConstantTween(const ColourPalette.dark());

  @override
  void initState() {
    super.initState();

    subscribeToUpdateStream();

    connect();

    colourPaletteController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    colourPaletteController.dispose();
    updateStreamSubscription?.cancel();
    previewStream.close();
    streams.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(
        child: SetColourPalette(
          colourPalette: colourPalette.evaluate(colourPaletteController),
          child: SMuFLProvider(
            child: Builder(
              builder: (context) => Row(
                children: [
                  LeftTabs(
                    keepHiddenChildrenAlive: true,
                    children: [
                      TabEntry(
                        icon: const Text('Programme').rotated(quarterTurns: 1),
                        body: ProgrammePanel(
                          requestUpdateStreamSink:
                              streams.requestUpdateStreamSink,
                          updateStream: streams.updateStream,
                          updateStreamSink: streams.updateStreamSink,
                          previewStream: previewStream.stream,
                          previewStreamSink: previewStream.sink,
                          liveStream: streams.liveStream,
                          liveStreamSink: streams.liveStreamSink,
                        ),
                      ),
                      TabEntry(
                        icon: const Text('Outputs').rotated(quarterTurns: 1),
                        body: OutputSettingsPanel(
                          requestUpdateStreamSink:
                              streams.requestUpdateStreamSink,
                          updateStream: streams.updateStream,
                          updateStreamSink: streams.updateStreamSink,
                        ),
                      ),
                      TabEntry(
                        icon: const Text('Settings').rotated(quarterTurns: 1),
                        body: ClientSettingsPanel(
                          serverAddress: serverAddress,
                          setServerAddress: (newServerAddress) => setState(() {
                            serverAddress = newServerAddress;
                            connect();
                          }),
                          connected: connected,
                          connect: connect,
                          disconnect: disconnect,
                          setColourPalette: (newColourPalette) {
                            colourPaletteController.stop();
                            colourPalette = ColourPaletteTween(
                              begin: colourPalette
                                  .evaluate(colourPaletteController),
                              end: newColourPalette,
                            );
                            colourPaletteController.reset();
                            colourPaletteController.forward();
                          },
                        ),
                      ),
                    ],
                  ).expanded(),
                  VerticalDivider(
                    width: 5,
                    thickness: 5,
                    color: ColourPalette.of(context).secondaryBackground,
                  ),
                  PreviewPanel(
                    requestUpdateStreamSink: streams.requestUpdateStreamSink,
                    updateStream: streams.updateStream,
                    updateStreamSink: streams.updateStreamSink,
                    previewStream: previewStream.stream,
                    liveStreamSink: streams.liveStreamSink,
                  ).expanded(),
                  VerticalDivider(
                    width: 5,
                    thickness: 5,
                    color: ColourPalette.of(context).secondaryBackground,
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
              }),
            ),
          ),
        ),
      ),
    );
  }
}
