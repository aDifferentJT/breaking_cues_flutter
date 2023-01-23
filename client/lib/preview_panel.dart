import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'colours.dart';
import 'deck_panel.dart';
import 'docked_preview.dart';
import 'fetch_panel.dart';
import 'left_tabs.dart';
import 'settings_controls.dart';

class GoLiveButtons extends StatelessWidget {
  final void Function({required bool quiet}) goLive;

  const GoLiveButtons({
    super.key,
    required this.goLive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Spacer(),
            Icon(
              CupertinoIcons.film,
              color: ColourPalette.of(context).background,
            ),
            Icon(
              CupertinoIcons.right_chevron,
              color: ColourPalette.of(context).background,
            ),
            const Spacer(),
          ],
        )
            .centered()
            .background(ColourPalette.of(context).danger)
            .gestureDetector(onTap: () => goLive(quiet: false))
            .expanded(flex: 3),
        Divider(
          height: 2,
          thickness: 2,
          color: ColourPalette.of(context).secondaryBackground,
        ),
        Row(
          children: [
            const Spacer(),
            Icon(
              CupertinoIcons.exclamationmark,
              color: ColourPalette.of(context).background,
            ),
            Icon(
              CupertinoIcons.right_chevron,
              color: ColourPalette.of(context).background,
            ),
            const Spacer(),
          ],
        )
            .centered()
            .background(ColourPalette.of(context).danger)
            .gestureDetector(onTap: () => goLive(quiet: true))
            .expanded(flex: 2),
      ],
    ).sized(width: 75);
  }
}

class PreviewPanel extends StatefulWidget {
  final StreamSink<void> requestUpdateStreamSink;
  final Stream<Programme> updateStream;
  final StreamSink<Programme> updateStreamSink;
  final Stream<DeckKey?> previewStream;
  final StreamSink<Message> liveStreamSink;

  const PreviewPanel({
    super.key,
    required this.requestUpdateStreamSink,
    required this.updateStream,
    required this.updateStreamSink,
    required this.previewStream,
    required this.liveStreamSink,
  });

  @override
  createState() => PreviewPanelState();
}

class PreviewPanelState extends State<PreviewPanel>
    with SingleTickerProviderStateMixin {
  var programme = Programme.new_();
  DeckIndex? deckIndex;
  bool searching = false;

  Index? get selected => deckIndex?.index;

  late StreamSubscription<Programme> _updateStreamSubscription;
  late StreamSubscription<DeckKey?> _previewStreamSubscription;

  final outputStream = StreamController<Message>.broadcast();
  Message lastMessage = CloseMessage();
  late final StreamSubscription<Message> _outputStreamSubscription;

  final requestPreviewUpdateStream = StreamController<void>();
  late final StreamSubscription<void> _requestPreviewUpdateStreamSubscription;

  void processUpdate(Programme newProgramme) {
    setState(() => programme = newProgramme);
    if (deckIndex != null) {
      final deck = programme.decks.cast<Deck?>().firstWhere(
            (deck) => deck?.key == deckIndex!.deck.key,
            orElse: () => null,
          );
      if (deck == null) {
        outputStream.add(CloseMessage());
      } else {
        outputStream.add(ShowMessage(
          defaultSettings: programme.defaultSettings,
          quiet: true,
          deckIndex: deckIndex!.withDeck(deck),
        ));
      }
    }
  }

  void processPreview(DeckKey? key) {
    if (key != null) {
      outputStream.add(ShowMessage(
        defaultSettings: programme.defaultSettings,
        quiet: false,
        deckIndex: DeckIndex(
          deck: programme.decks.firstWhere((deck) => deck.key == key),
          index: Index.zero,
        ),
      ));
    } else {
      outputStream.add(CloseMessage());
    }
  }

  void processOutput(Message message) {
    lastMessage = message;
    if (message is ShowMessage) {
      setState(() => deckIndex = message.deckIndex);
    } else if (message is CloseMessage) {
      setState(() => deckIndex = null);
    } else {
      throw ArgumentError.value(message, "Message type not recognised");
    }
  }

  void updateDeck(Deck newDeck) {
    widget.updateStreamSink.add(
      programme.withDecks(
        programme.decks
            .map((deck) => deck.key == newDeck.key ? newDeck : deck)
            .toBuiltList(),
      ),
    );
  }

  void select(Index index) {
    if (deckIndex != null) {
      outputStream.add(ShowMessage(
        defaultSettings: programme.defaultSettings,
        quiet: true,
        deckIndex: DeckIndex(
          deck: deckIndex!.deck,
          index: index,
        ),
      ));
    }
  }

  @override
  void initState() {
    super.initState();

    _updateStreamSubscription = widget.updateStream.listen(processUpdate);
    _previewStreamSubscription = widget.previewStream.listen(processPreview);
    _outputStreamSubscription = outputStream.stream.listen(processOutput);
    _requestPreviewUpdateStreamSubscription = requestPreviewUpdateStream.stream
        .listen((_) => outputStream.add(lastMessage));

    widget.requestUpdateStreamSink.add(null);
  }

  @override
  void didUpdateWidget(covariant PreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.updateStream != oldWidget.updateStream) {
      _updateStreamSubscription.cancel();
      _updateStreamSubscription = widget.updateStream.listen(processUpdate);
    }
    if (widget.previewStream != oldWidget.previewStream) {
      _previewStreamSubscription.cancel();
      _previewStreamSubscription = widget.previewStream.listen(processPreview);
    }
  }

  @override
  dispose() {
    _requestPreviewUpdateStreamSubscription.cancel();
    _updateStreamSubscription.cancel();
    _previewStreamSubscription.cancel();
    _outputStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      LayoutBuilder(builder: (context, constraints) {
        return Column(children: [
          (deckIndex == null
                  ? const Text("Nothing Selected")
                      .centered()
                      .background(ColourPalette.of(context).background)
                  : LeftTabs(
                      keepHiddenChildrenAlive: false,
                      children: [
                        TabEntry(
                          icon: const Text("Preview").rotated(quarterTurns: 1),
                          body: DeckPanel(
                            deckIndex: deckIndex!,
                            select: select,
                          ),
                        ),
                        TabEntry(
                          icon: const Text("Editor").rotated(quarterTurns: 1),
                          body: EditingDeckPanel(
                            stream: outputStream.sink,
                            defaultSettings: programme.defaultSettings,
                            deckIndex: deckIndex!,
                            select: select,
                            onChange: updateDeck,
                          ),
                        ),
                        TabEntry(
                          icon: const Text("Fetch").rotated(quarterTurns: 1),
                          body: FetchPanel(
                            deckKey: deckIndex!.deck.key,
                            updateDeck: updateDeck,
                          ),
                        ),
                        TabEntry(
                          icon: const Text("Settings").rotated(quarterTurns: 1),
                          body: Column(children: [
                            Text(
                              '${deckIndex?.deck.label ?? ''} Settings',
                              style: ColourPalette.of(context).headingStyle,
                            ).container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.all(16),
                                color: ColourPalette.of(context)
                                    .secondaryBackground),
                            OptionalDisplaySettingsPanel(
                              displaySettings: deckIndex!.deck.displaySettings
                                  .rebuild((builder) {
                                for (final name
                                    in programme.defaultSettings.keys) {
                                  builder.putIfAbsent(
                                    name,
                                    () => const OptionalDisplaySettings(),
                                  );
                                }
                              }),
                              update: (settings) => updateDeck(
                                deckIndex!.deck.withDisplaySettings(settings),
                              ),
                              defaultSettings: programme.defaultSettings,
                            )
                                .background(
                                    ColourPalette.of(context).background)
                                .expanded(),
                          ]),
                        ),
                      ],
                    ))
              .expanded(),
          DockedPreview(
            requestUpdateStreamSink: requestPreviewUpdateStream.sink,
            stream: outputStream.stream,
            defaultSettings: programme.defaultSettings,
            deck: deckIndex?.deck,
            updateDeck: updateDeck,
          ).constrained(constraints),
        ]);
      }).expanded(),
      GoLiveButtons(
        goLive: ({required quiet}) {
          if (deckIndex != null) {
            widget.liveStreamSink.add(ShowMessage(
              defaultSettings: programme.defaultSettings,
              quiet: quiet,
              deckIndex: deckIndex!,
            ));
          }
        },
      ),
    ]);
  }
}
