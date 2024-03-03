import 'dart:async';
import 'dart:io';

import 'package:core/deck.dart';
import 'package:core/media_library.dart';
import 'package:core/pubsub.dart';
import 'package:core/server.dart';
import 'package:core/streams.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_utils/widget_modifiers.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
        onError: (error) => Response.notFound(null),
      );
}

void main() {
  //debugFocusChanges = true;
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
  final uuid = const Uuid().v4obj();

  var programme =
      Programme.new_(); // Only used for saving, setState not required

  final mediaLibrary = MediaLibrary();

  String serverAddress = "ws://127.0.0.1:8080";

  StreamSubscription<Update>? updateStreamSubscription;
  void subscribeToUpdateStream() {
    updateStreamSubscription?.cancel();
    updateStreamSubscription = pubSubs.update.subscribe((update) {
      programme = update.programme;

      Future.wait(programme.mediaUuids.map((uuid) {
        if (mediaLibrary[uuid] != null) {
          return Future.value();
        } else {
          final uri =
              Uri.tryParse('$serverAddress/media?uuid=${uuid.toString()}');
          if (uri == null) {
            return Future.value();
          } else {
            return http
                .get(uri)
                .then((response) => response.bodyBytes)
                .then(Media.fromBytes)
                .then(mediaLibrary.insert);
          }
        }
      }));
    });
  }

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
  ClientStreams get pubSubs => remoteStreams ?? localStreams;

  final previewPubSub = PubSubController<DeckKeyIndex?>(initialValue: null);

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
    previewPubSub.dispose();
    pubSubs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(
        child: SetColourPalette(
          colourPalette: colourPalette.evaluate(colourPaletteController),
          child: Builder(
            builder: (context) => Row(
              children: [
                LeftTabs(
                  keepHiddenChildrenAlive: true,
                  children: [
                    TabEntry(
                      debugLabel: 'Programme',
                      icon: const Text('Programme').rotated(quarterTurns: 1),
                      body: ProgrammePanel(
                        update: pubSubs.update,
                        preview: previewPubSub,
                        live: pubSubs.live,
                      ),
                    ),
                    TabEntry(
                      debugLabel: 'Outputs',
                      icon: const Text('Outputs').rotated(quarterTurns: 1),
                      body: OutputSettingsPanel(
                        updateStream: pubSubs.update,
                      ),
                    ),
                    TabEntry(
                      debugLabel: "Client Settings",
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
                            begin:
                                colourPalette.evaluate(colourPaletteController),
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
                  update: pubSubs.update,
                  preview: previewPubSub,
                  live: pubSubs.live,
                ).expanded(),
                VerticalDivider(
                  width: 5,
                  thickness: 5,
                  color: ColourPalette.of(context).secondaryBackground,
                ),
                LivePanel(
                  pubSub: pubSubs.live,
                ).expanded(),
              ],
            ).callbackShortcuts(bindings: {
              SingleActivator(
                LogicalKeyboardKey.keyN,
                control: !(Platform.isMacOS || Platform.isIOS),
                meta: Platform.isMacOS || Platform.isIOS,
              ): () => pubSubs.update.publish(Update(
                    programme: Programme.new_(),
                    source: uuid,
                  )),
              SingleActivator(
                LogicalKeyboardKey.keyO,
                control: !(Platform.isMacOS || Platform.isIOS),
                meta: Platform.isMacOS || Platform.isIOS,
              ): () async {
                var newProgramme = await open();
                if (newProgramme != null) {
                  pubSubs.update.publish(Update(
                    programme: newProgramme,
                    source: uuid,
                  ));
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
    );
  }
}
