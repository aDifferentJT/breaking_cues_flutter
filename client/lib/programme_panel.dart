import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
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
          child: const Icon(CupertinoIcons.delete_solid)
              .padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).danger,
          filledChildColour: ColourPalette.of(context).background,
          onTap: delete,
        ),
        PackedButton(
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
      Row(children: [
        Text(label),
        const Spacer(),
        ProgrammeRowButtons(
          rowIndex: rowIndex,
          deckKey: deckKey,
          selected: selected,
          delete: onDelete,
          isLive: isLive,
          goLive: goLive,
          closeLive: closeLive,
        )
      ])
          .container(
            padding: const EdgeInsets.all(10),
            color: selected
                ? ColourPalette.of(context).active
                : ColourPalette.of(context).background,
          )
          .gestureDetector(onTap: onSelect),
      Divider(
        color: ColourPalette.of(context).secondaryBackground,
        height: 0,
        thickness: 1,
      ),
    ]);
  }
}

class ProgrammePanel extends StatefulWidget {
  final StreamSink<void> requestUpdateStreamSink;
  final Stream<Programme> updateStream;
  final StreamSink<Programme> updateStreamSink;
  final Stream<DeckKey?> previewStream;
  final StreamSink<DeckKey?> previewStreamSink;
  final Stream<Message> liveStream;
  final StreamSink<Message> liveStreamSink;

  const ProgrammePanel({
    super.key,
    required this.requestUpdateStreamSink,
    required this.updateStream,
    required this.updateStreamSink,
    required this.previewStream,
    required this.previewStreamSink,
    required this.liveStream,
    required this.liveStreamSink,
  });

  @override
  createState() => _ProgrammePanelState();
}

class _ProgrammePanelState extends State<ProgrammePanel> {
  var programme = Programme.new_();

  DeckKey? previewDeck;
  Deck? liveDeck;

  late StreamSubscription<Programme> _updateStreamSubscription;
  late StreamSubscription<DeckKey?> _previewStreamSubscription;
  late StreamSubscription<Message> _liveStreamSubscription;

  void processUpdate(Programme newProgramme) =>
      setState(() => programme = newProgramme);

  void processPreview(DeckKey? key) => setState(() => previewDeck = key);

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

    _updateStreamSubscription = widget.updateStream.listen(processUpdate);
    _previewStreamSubscription = widget.previewStream.listen(processPreview);
    _liveStreamSubscription = widget.liveStream.listen(processLive);
  }

  @override
  void didUpdateWidget(covariant ProgrammePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.updateStream != oldWidget.updateStream) {
      _updateStreamSubscription.cancel();
      _updateStreamSubscription = widget.updateStream.listen(processUpdate);
    }
    if (widget.previewStream != oldWidget.previewStream) {
      _previewStreamSubscription.cancel();
      _previewStreamSubscription = widget.previewStream.listen(processPreview);
    }
    if (widget.liveStream != oldWidget.liveStream) {
      _liveStreamSubscription.cancel();
      _liveStreamSubscription = widget.liveStream.listen(processLive);
    }
    widget.requestUpdateStreamSink.add(null);
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
    return Column(
      children: [
        Row(
          children: [
            Text(
              "Programme",
              style: ColourPalette.of(context).headingStyle,
            ).expanded(),
            PackedButtonRow(
              buttons: [
                PackedButton(
                  child: const Icon(CupertinoIcons.doc)
                      .padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).active,
                  filledChildColour:
                      ColourPalette.of(context).secondaryBackground,
                  onTap: () => widget.updateStreamSink.add(Programme.new_()),
                ),
                PackedButton(
                  child: const Icon(CupertinoIcons.folder_open)
                      .padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).active,
                  filledChildColour:
                      ColourPalette.of(context).secondaryBackground,
                  onTap: () async {
                    var programme = await open();
                    if (programme != null) {
                      widget.updateStreamSink.add(programme);
                    }
                  },
                ),
                PackedButton(
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
                  child: const Icon(CupertinoIcons.add)
                      .padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).active,
                  filledChildColour:
                      ColourPalette.of(context).secondaryBackground,
                  onTap: () => widget.updateStreamSink.add(
                    programme.withDecks(
                      programme.decks.rebuild((builder) {
                        builder.insert(
                          programme.decks.indexWhere(
                                  (deck) => deck.key == previewDeck) +
                              1,
                          Deck(
                            key: DeckKey.distinctFrom(
                              programme.decks.map((deck) => deck.key),
                            ),
                          ),
                        );
                      }),
                    ),
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
                  widget.updateStreamSink.add(
                    programme.mapDecks(
                      (decks) => decks.rebuild((builder) {
                        final deck = builder.removeAt(oldIndex);
                        builder.insert(newIndex, deck);
                      }),
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
                  selected: deck.key == previewDeck,
                  onSelect: () {
                    widget.previewStreamSink.add(deck.key);
                  },
                  onDelete: () => widget.updateStreamSink.add(
                    programme.withDecks(
                      programme.decks.rebuild(
                        (decks) =>
                            decks.removeWhere((deck_) => deck_.key == deck.key),
                      ),
                    ),
                  ),
                  isLive: liveDeck?.key == deck.key,
                  goLive: () => widget.liveStreamSink.add(ShowMessage(
                    defaultSettings: programme.defaultSettings,
                    quiet: false,
                    deckIndex: DeckIndex(deck: deck, index: Index.zero),
                  )),
                  closeLive: () => widget.liveStreamSink.add(CloseMessage()),
                );
              },
              itemCount: programme.decks.length,
            ),
          ),
        ),
      ],
    );
  }
}
