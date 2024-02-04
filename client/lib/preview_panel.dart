import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:core/pubsub.dart';
import 'package:core/streams.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
import 'package:flutter_utils/pubsub_builder.dart';
import 'package:flutter_utils/widget_modifiers.dart';
import 'package:uuid/uuid.dart';

import 'colours.dart';
import 'deck_panel.dart';
import 'docked_preview.dart';
import 'editing_deck_panel.dart';
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
  final PubSub<Update> update;
  final PubSub<DeckKeyIndex?> preview;
  final PubSub<Message> live;

  const PreviewPanel({
    super.key,
    required this.update,
    required this.preview,
    required this.live,
  });

  @override
  createState() => PreviewPanelState();
}

class PreviewPanelState extends State<PreviewPanel>
    with SingleTickerProviderStateMixin {
  final uuid = const Uuid().v4obj();

  bool isDeck = false;
  BuiltMap<String, DisplaySettings> defaultSettings = BuiltMap();

  final previewOutput = PubSubController<Message>(initialValue: CloseMessage());
  late CachedPubSub<(DeckIndex?, UuidValue?)> preview;

  late StreamSubscription<Update> updateSubscription;
  late StreamSubscription<(DeckIndex?, UuidValue?)> previewSubscription;

  void processUpdate(Update update) {
    final newDefaultSettings = update.programme.defaultSettings;
    if (defaultSettings != newDefaultSettings) {
      defaultSettings = newDefaultSettings;
    }
  }

  void processPreview((DeckIndex?, UuidValue?) value) {
    final (deckIndex, _) = value;

    if (deckIndex != null) {
      previewOutput.publish(ShowMessage(
        defaultSettings: defaultSettings,
        quiet: true,
        deckIndex: deckIndex,
      ));
    } else {
      previewOutput.publish(CloseMessage());
    }

    final newIsDeck = deckIndex != null;
    if (isDeck != newIsDeck) {
      setState(() => isDeck = newIsDeck);
    }
  }

  void updateDeck(Deck deck, {required bool refresh}) {
    // TODO
    preview.publish((preview.value!.$1!.withDeck(deck), refresh ? null : uuid));
  }

  @deprecated
  void select(Index index) {
    if (preview.value != null) {
      final (deckIndex, _) = preview.value!;
      if (deckIndex != null) {
        widget.preview.publish(DeckKeyIndex(
          key: deckIndex.deck.key,
          index: index,
        ));
      }
    }
  }

  void initPreviewPubSub() {
    ((DeckIndex?, UuidValue?)?, Programme?) down(
        (Update, DeckKeyIndex? deckKeyIndex)? value, Programme? state) {
      final (programmeUpdate, deckKeyIndex) = value!;
      if (deckKeyIndex == null) {
        return (null, null);
      } else {
        return (
          (
            programmeUpdate.programme.deckIndexForKey(deckKeyIndex),
            programmeUpdate.source,
          ),
          programmeUpdate.programme,
        );
      }
    }

    ((Update, DeckKeyIndex?)?, Programme?) up(
        (DeckIndex?, UuidValue?)? value, Programme? oldProgramme) {
      final (deckIndex, source) = value!;
      if (oldProgramme == null) {
        return (null, null);
      } else {
        return (
          deckIndex == null
              ? (Update(programme: oldProgramme, source: source), null)
              : (
                  Update(
                    programme: oldProgramme.withDecks(
                      oldProgramme.decks
                          .map(
                            (deck) => deck.key == deckIndex.deck.key
                                ? deckIndex.deck
                                : deck,
                          )
                          .toBuiltList(),
                    ),
                    source: source,
                  ),
                  DeckKeyIndex(key: deckIndex.deck.key, index: deckIndex.index)
                ),
          oldProgramme
        );
      }
    }

    preview = ZipPubSub(widget.update.borrowed, widget.preview.borrowed)
        .filterUpwardNulls
        .statefulMap(null, down, up)
        .filterDownwardNulls
        .cached();

    previewSubscription = preview.subscribe(processPreview);
  }

  @override
  void initState() {
    super.initState();

    updateSubscription = widget.update.subscribe(processUpdate);
    initPreviewPubSub();
  }

  @override
  void didUpdateWidget(covariant PreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.update != oldWidget.update) {
      updateSubscription.cancel();
      updateSubscription = widget.update.subscribe(processUpdate);
    }
    if (widget.update != oldWidget.update ||
        widget.preview != oldWidget.preview) {
      previewSubscription.cancel();
      preview.dispose();
      initPreviewPubSub();
    }
  }

  @override
  dispose() {
    updateSubscription.cancel();
    previewSubscription.cancel();
    preview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      LayoutBuilder(builder: (context, constraints) {
        return Column(children: [
          (isDeck
                  ? LeftTabs(
                      keepHiddenChildrenAlive: false,
                      children: [
                        TabEntry(
                          debugLabel: "Preview",
                          icon: const Text("Preview").rotated(quarterTurns: 1),
                          body: PreviewDeckPanelPubSub(
                            update: widget.update,
                            preview: widget.preview,
                            select: select,
                          ),
                        ),
                        TabEntry(
                          debugLabel: "Editor",
                          icon: const Text("Editor").rotated(quarterTurns: 1),
                          body: EditingDeckPanel(
                            deckIndex: preview,
                          ),
                        ),
                        TabEntry(
                          debugLabel: "Fetch",
                          icon: const Text("Fetch").rotated(quarterTurns: 1),
                          body: FetchPanel(
                            updateChunks: (chunks) => updateDeck(
                              preview.value!.$1!.deck.withChunks(chunks),
                              refresh: true,
                            ),
                          ),
                        ),
                        TabEntry(
                          debugLabel: "Deck Settings",
                          icon: const Text("Settings").rotated(quarterTurns: 1),
                          body: Column(children: [
                            Text(
                              '${preview.value?.$1?.deck.label ?? ''} Settings',
                              style: ColourPalette.of(context).headingStyle,
                            ).container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.all(16),
                                color: ColourPalette.of(context)
                                    .secondaryBackground),
                            PubSubBuilder(
                                pubSub: widget.update,
                                builder: (context, update) {
                                  final defaultSettings =
                                      update?.programme.defaultSettings;
                                  if (defaultSettings == null) {
                                    return Text(
                                      "Loading",
                                      style:
                                          ColourPalette.of(context).bodyStyle,
                                    ).centered().background(
                                        ColourPalette.of(context).background);
                                  } else {
                                    return OptionalDisplaySettingsPanel(
                                      displaySettings: preview
                                          .value!.$1!.deck.displaySettings
                                          .rebuild((builder) {
                                        for (final name
                                            in defaultSettings.keys) {
                                          builder.putIfAbsent(
                                            name,
                                            () =>
                                                const OptionalDisplaySettings(),
                                          );
                                        }
                                      }),
                                      update: (settings) => updateDeck(
                                        preview.value!.$1!.deck
                                            .withDisplaySettings(settings),
                                        refresh: true,
                                      ),
                                      defaultSettings: defaultSettings,
                                    )
                                        .background(ColourPalette.of(context)
                                            .background)
                                        .expanded();
                                  }
                                }),
                          ]),
                        ),
                      ],
                    )
                  : const Text("Nothing Selected")
                      .centered()
                      .background(ColourPalette.of(context).background))
              .expanded(),
          PubSubBuilder(
            pubSub: widget.update,
            builder: (context, update) {
              final defaultSettings = update?.programme.defaultSettings;
              if (defaultSettings == null) {
                return Text(
                  "Loading",
                  style: ColourPalette.of(context).bodyStyle,
                ).centered().background(ColourPalette.of(context).background);
              } else {
                return DockedPreview(
                  pubSub: previewOutput,
                  defaultSettings: defaultSettings,
                  deck: preview.value?.$1?.deck,
                ).constrained(constraints);
              }
            },
          ),
        ]);
      }).expanded(),
      PubSubBuilder<Update>(
        pubSub: widget.update,
        builder: (context, update) {
          final defaultSettings = update?.programme.defaultSettings;
          if (defaultSettings == null) {
            return Text(
              "Loading",
              style: ColourPalette.of(context).bodyStyle,
            ).centered().background(ColourPalette.of(context).background);
          } else {
            return GoLiveButtons(
              goLive: ({required quiet}) {
                final deckIndex = preview.value?.$1;
                if (deckIndex != null) {
                  widget.live.publish(ShowMessage(
                    defaultSettings: defaultSettings,
                    quiet: quiet,
                    deckIndex: deckIndex,
                  ));
                }
              },
            );
          }
        },
      ),
    ]);
  }
}
