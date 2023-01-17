import 'dart:async';
import 'dart:ui';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'button.dart';
import 'deck_panel.dart';
import 'docked_preview.dart';
import 'left_tabs.dart';
import 'settings_controls.dart';
import 'suggestor.dart';

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
          children: const [
            Spacer(),
            Icon(
              CupertinoIcons.film,
              color: Colors.black,
            ),
            Icon(
              CupertinoIcons.right_chevron,
              color: Colors.black,
            ),
            Spacer(),
          ],
        )
            .centered()
            .background(const Color.fromARGB(255, 255, 0, 0))
            .gestureDetector(onTap: () => goLive(quiet: false))
            .expanded(flex: 3),
        const Divider(
          height: 2,
          thickness: 2,
          color: CupertinoColors.darkBackgroundGray,
        ),
        Row(
          children: const [
            Spacer(),
            Icon(
              CupertinoIcons.exclamationmark,
              color: Colors.black,
            ),
            Icon(
              CupertinoIcons.right_chevron,
              color: Colors.black,
            ),
            Spacer(),
          ],
        )
            .centered()
            .background(const Color.fromARGB(255, 255, 0, 0))
            .gestureDetector(onTap: () => goLive(quiet: true))
            .expanded(flex: 2),
      ],
    ).sized(width: 75);
  }
}

class SearchOverlay extends StatefulWidget {
  const SearchOverlay({super.key, required this.dismiss});

  final void Function() dismiss;

  @override
  SearchOverlayState createState() => SearchOverlayState();
}

class SearchOverlayState extends State<SearchOverlay> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Stack(
          children: [
            GestureDetector(onTap: widget.dismiss),
            Column(children: [
              CupertinoSearchTextField(controller: searchController),
              ...suggestor.results(searchController.text).map(
                    (suggestion) => Text(suggestion.title).container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.black,
                    ),
                  ),
              ...suggestor.completions(searchController.text).map(
                    (completion) => Text("$completion...")
                        .container(
                          padding: const EdgeInsets.all(10),
                          color: Colors.black,
                        )
                        .gestureDetector(
                            onTap: () => setState(
                                () => searchController.text = completion)),
                  ),
            ]).padding(const EdgeInsets.all(25)),
          ],
        ),
      ),
    );
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
  bool editing = false;
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
    _updateStreamSubscription.cancel();
    _previewStreamSubscription.cancel();
    _outputStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(
        children: [
          Row(
            children: [
              (editing
                  ? TextFormField(
                      initialValue: deckIndex?.deck.comment ?? "",
                      decoration: InputDecoration.collapsed(
                        hintText: deckIndex?.deck.label ?? "",
                      ),
                      style: Theme.of(context).primaryTextTheme.headlineSmall,
                      onChanged: (comment) {
                        if (deckIndex != null) {
                          updateDeck(
                            deckIndex!.deck.withComment(comment),
                          );
                        }
                      },
                    ).expanded()
                  : Text(
                      deckIndex?.deck.label ?? "Preview",
                      style: Theme.of(context).primaryTextTheme.headlineSmall,
                    ).expanded()),
              Button(
                onTap: () => setState(() => searching = true),
                child: const Icon(
                  CupertinoIcons.search,
                  color: CupertinoColors.activeBlue,
                ),
              ).padding(const EdgeInsets.symmetric(horizontal: 4)),
              Button(
                onTap: () => setState(() => editing = !editing),
                depressed: editing,
                child: Icon(
                  CupertinoIcons.pencil,
                  color: editing
                      ? CupertinoColors.darkBackgroundGray
                      : CupertinoColors.activeBlue,
                ),
              ).padding(const EdgeInsets.symmetric(horizontal: 4)),
            ],
          ).container(
            padding: const EdgeInsets.all(20),
            color: CupertinoColors.darkBackgroundGray,
          ),
          Row(children: [
            LayoutBuilder(builder: (context, constraints) {
              return Column(children: [
                (deckIndex == null
                        ? const Text("Nothing Selected")
                            .centered()
                            .background(Colors.black)
                        : LeftTabs(
                            keepHiddenChildrenAlive: true,
                            children: [
                              TabEntry(
                                icon: const Text("Preview")
                                    .rotated(quarterTurns: 1),
                                body: ConditionalEditingDeckPanel(
                                  stream: outputStream.sink,
                                  defaultSettings: programme.defaultSettings,
                                  deckIndex: deckIndex!,
                                  editing: editing,
                                  onChange: updateDeck,
                                ),
                              ),
                              TabEntry(
                                icon: const Text("Settings")
                                    .rotated(quarterTurns: 1),
                                body: OptionalDisplaySettingsPanel(
                                  displaySettings: deckIndex!
                                      .deck.displaySettings
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
                                    deckIndex!.deck
                                        .withDisplaySettings(settings),
                                  ),
                                  defaultSettings: programme.defaultSettings,
                                ).background(Colors.black),
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
          ]).expanded(),
        ],
      ),
      searching
          ? SearchOverlay(dismiss: () => setState(() => searching = false))
          : const SizedBox.shrink(),
    ]);
  }
}
