import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:core/pubsub.dart';
import 'package:core/streams.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
import 'package:flutter/services.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'colours.dart';
import 'packed_button_row.dart';
import 'open_save.dart';

class ProgrammeRowButtons extends StatelessWidget {
  final int rowIndex;
  final DeckKey deckKey;
  final bool selected;
  final void Function() delete;
  final bool isLive;
  final void Function() goLive;
  final void Function() closeLive;

  const ProgrammeRowButtons({
    super.key,
    required this.rowIndex,
    required this.deckKey,
    required this.selected,
    required this.delete,
    required this.isLive,
    required this.goLive,
    required this.closeLive,
  });

  @override
  Widget build(BuildContext context) {
    return PackedButtonRow(
      buttons: [
        PackedButton(
          debugLabel: "Delete Deck",
          child: const Icon(CupertinoIcons.delete_solid)
              .padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).danger,
          filledChildColour: ColourPalette.of(context).background,
          onTap: delete,
        ),
        PackedButton(
          debugLabel: "Deck Reorder Handle",
          child: const Icon(CupertinoIcons.arrow_up_arrow_down)
              .padding(const EdgeInsets.all(1)),
          colour: selected
              ? ColourPalette.of(context).background
              : ColourPalette.of(context).active,
          filledChildColour: ColourPalette.of(context).background,
          wrapper: (child) => ReorderableDragStartListener(
            index: rowIndex,
            child: child,
          ),
        ),
        PackedButton(
          debugLabel: "Programme Row Go Live",
          child:
              const Icon(CupertinoIcons.film).padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).danger,
          filled: isLive,
          filledChildColour: ColourPalette.of(context).background,
          onTap: isLive ? closeLive : goLive,
        ),
      ].toBuiltList(),
      padding: const EdgeInsets.all(1),
    );
  }
}

class ProgrammeRow extends StatelessWidget {
  final int rowIndex;
  final DeckKey deckKey;
  final String label;
  final bool selected;
  final void Function() onSelect;
  final void Function() onDelete;
  final bool isLive;
  final void Function() goLive;
  final void Function() closeLive;

  const ProgrammeRow({
    super.key,
    required this.rowIndex,
    required this.deckKey,
    required this.label,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.isLive,
    required this.goLive,
    required this.closeLive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Divider(
        color: ColourPalette.of(context).secondaryBackground,
        height: 0,
        thickness: 1,
      ),
      Builder(
        builder: (context) => Row(children: [
          Expanded(child: Text(label)),
          ProgrammeRowButtons(
            rowIndex: rowIndex,
            deckKey: deckKey,
            selected: selected,
            delete: onDelete,
            isLive: isLive,
            goLive: goLive,
            closeLive: closeLive,
          )
        ]).container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? ColourPalette.of(context).active
                : ColourPalette.of(context).background,
            boxShadow: Focus.of(context).hasPrimaryFocus
                ? [ColourPalette.of(context).focusedShadow()]
                : null,
          ),
        ),
      ).focus().gestureDetector(onTap: onSelect).callbackShortcuts(bindings: {
        const SingleActivator(LogicalKeyboardKey.space): onSelect,
      }),
      Divider(
        color: ColourPalette.of(context).secondaryBackground,
        height: 0,
        thickness: 1,
      ),
    ]);
  }
}

class ProgrammePanel extends StatefulWidget {
  final PubSub<Update> update;
  final PubSub<DeckKeyIndex?> preview;
  final PubSub<Message> live;

  const ProgrammePanel({
    super.key,
    required this.update,
    required this.preview,
    required this.live,
  });

  @override
  createState() => _ProgrammePanelState();
}

class _ProgrammePanelState extends State<ProgrammePanel> {
  var programme = Programme.new_();

  DeckKeyIndex? previewDeck;
  Deck? liveDeck;

  late StreamSubscription<Update> _updateStreamSubscription;
  late StreamSubscription<DeckKeyIndex?> _previewStreamSubscription;
  late StreamSubscription<Message> _liveStreamSubscription;

  void processUpdate(Update update) =>
      setState(() => programme = update.programme);

  void processPreview(DeckKeyIndex? deckKeyIndex) =>
      setState(() => previewDeck = deckKeyIndex);

  void processLive(Message message) {
    if (message is ShowMessage) {
      setState(() => liveDeck = message.deckIndex.deck);
    } else if (message is CloseMessage) {
      setState(() => liveDeck = null);
    } else {
      throw ArgumentError.value(message, "Message type not recognised");
    }
  }

  @override
  void initState() {
    super.initState();

    _updateStreamSubscription = widget.update.subscribe(processUpdate);
    _previewStreamSubscription = widget.preview.subscribe(processPreview);
    _liveStreamSubscription = widget.live.subscribe(processLive);
  }

  @override
  void didUpdateWidget(covariant ProgrammePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.update != oldWidget.update) {
      _updateStreamSubscription.cancel();
      _updateStreamSubscription = widget.update.subscribe(processUpdate);
    }
    if (widget.preview != oldWidget.preview) {
      _previewStreamSubscription.cancel();
      _previewStreamSubscription = widget.preview.subscribe(processPreview);
    }
    if (widget.live != oldWidget.live) {
      _liveStreamSubscription.cancel();
      _liveStreamSubscription = widget.live.subscribe(processLive);
    }
  }

  @override
  dispose() {
    _updateStreamSubscription.cancel();
    _previewStreamSubscription.cancel();
    _liveStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Column(
        children: [
          FocusTraversalGroup(
            child: Row(
              children: [
                Text(
                  "Programme",
                  style: ColourPalette.of(context).headingStyle,
                ).expanded(),
                PackedButtonRow(
                  buttons: [
                    PackedButton(
                      debugLabel: "New Programme",
                      child: const Icon(CupertinoIcons.doc)
                          .padding(const EdgeInsets.all(4)),
                      colour: ColourPalette.of(context).active,
                      filledChildColour:
                          ColourPalette.of(context).secondaryBackground,
                      onTap: () => widget.update.publish(Update(
                        programme: Programme.new_(),
                      )),
                    ),
                    PackedButton(
                      debugLabel: "Open Programme",
                      child: const Icon(CupertinoIcons.folder_open)
                          .padding(const EdgeInsets.all(4)),
                      colour: ColourPalette.of(context).active,
                      filledChildColour:
                          ColourPalette.of(context).secondaryBackground,
                      onTap: () async {
                        var programme = await open();
                        if (programme != null) {
                          widget.update.publish(Update(programme: programme));
                        }
                      },
                    ),
                    PackedButton(
                      debugLabel: "Save Programme",
                      child: const Icon(CupertinoIcons.floppy_disk)
                          .padding(const EdgeInsets.all(4)),
                      colour: ColourPalette.of(context).active,
                      filledChildColour:
                          ColourPalette.of(context).secondaryBackground,
                      onTap: () => save(programme),
                    ),
                  ].toBuiltList(),
                  padding: const EdgeInsets.all(1),
                ),
                const SizedBox(width: 4),
                PackedButtonRow(
                  buttons: [
                    PackedButton(
                      debugLabel: "New Deck",
                      child: const Icon(CupertinoIcons.add)
                          .padding(const EdgeInsets.all(4)),
                      colour: ColourPalette.of(context).active,
                      filledChildColour:
                          ColourPalette.of(context).secondaryBackground,
                      onTap: () => widget.update.publish(
                        Update(programme: programme.withDecks(
                          programme.decks.rebuild((builder) {
                            builder.insert(
                              programme.decks.indexWhere(
                                      (deck) => deck.key == previewDeck?.key) +
                                  1,
                              Deck(
                                key: DeckKey.distinctFrom(
                                  programme.decks.map((deck) => deck.key),
                                ),
                              ),
                            );
                          }),
                        )),
                      ),
                    ),
                  ].toBuiltList(),
                  padding: const EdgeInsets.all(1),
                ),
              ],
            ).container(
              padding: const EdgeInsets.all(20),
              color: ColourPalette.of(context).secondaryBackground,
            ),
          ),
          Expanded(
            child: Container(
              color: ColourPalette.of(context).background,
              child: ReorderableList(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      // removing the item at oldIndex will shorten the list by 1.
                      newIndex -= 1;
                    }
                    widget.update.publish(
                      Update(
                        programme: programme.mapDecks(
                          (decks) => decks.rebuild((builder) {
                            final deck = builder.removeAt(oldIndex);
                            builder.insert(newIndex, deck);
                          }),
                        ),
                      ),
                    );
                  });
                },
                itemBuilder: (context, rowIndex) {
                  final deck = programme.decks[rowIndex];
                  return ProgrammeRow(
                    key: Key("${deck.key}"),
                    rowIndex: rowIndex,
                    deckKey: deck.key,
                    label: deck.label,
                    selected: deck.key == previewDeck?.key,
                    onSelect: () {
                      widget.preview.publish(DeckKeyIndex(
                        key: deck.key,
                        index: Index.zero,
                      ));
                    },
                    onDelete: () => widget.update.publish(
                      Update(
                        programme: programme.withDecks(
                          programme.decks.rebuild(
                            (decks) => decks
                                .removeWhere((deck_) => deck_.key == deck.key),
                          ),
                        ),
                      ),
                    ),
                    isLive: liveDeck?.key == deck.key,
                    goLive: () => widget.live.publish(ShowMessage(
                      defaultSettings: programme.defaultSettings,
                      quiet: false,
                      deckIndex: DeckIndex(deck: deck, index: Index.zero),
                    )),
                    closeLive: () => widget.live.publish(CloseMessage()),
                  );
                },
                itemCount: programme.decks.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
