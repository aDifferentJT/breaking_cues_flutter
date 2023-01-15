import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'button.dart';
import 'open_save.dart';

class ProgrammeRowButtons extends StatelessWidget {
  const ProgrammeRowButtons({
    super.key,
    required this.rowIndex,
    required this.deckKey,
    required this.selected,
    required this.onDelete,
    required this.isLive,
    required this.goLive,
  });

  final int rowIndex;
  final DeckKey deckKey;
  final bool selected;
  final void Function() onDelete;
  final bool isLive;
  final void Function() goLive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(1),
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: CupertinoColors.destructiveRed,
                ),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(5),
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(
                CupertinoIcons.delete_solid,
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(1),
          child: ReorderableDragStartListener(
            index: rowIndex,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: selected ? Colors.black : CupertinoColors.activeBlue,
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Icon(
                CupertinoIcons.arrow_up_arrow_down,
                color: selected ? Colors.black : CupertinoColors.activeBlue,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(1),
          child: GestureDetector(
            onTap: goLive,
            child: Container(
              decoration: BoxDecoration(
                color: isLive ? Colors.red : Colors.transparent,
                border: Border.all(
                  color: const Color.fromARGB(255, 255, 0, 0),
                ),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(5),
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: Icon(
                CupertinoIcons.film,
                color: isLive
                    ? Colors.black
                    : const Color.fromARGB(255, 255, 0, 0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ProgrammeRow extends StatelessWidget {
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
  });

  final int rowIndex;
  final DeckKey deckKey;
  final String label;
  final bool selected;
  final void Function() onSelect;
  final void Function() onDelete;
  final bool isLive;
  final void Function() goLive;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(
          color: CupertinoColors.darkBackgroundGray,
          height: 0,
          thickness: 1,
        ),
        GestureDetector(
          onTap: () => onSelect(),
          child: Container(
            padding: const EdgeInsets.all(10),
            color: selected ? CupertinoColors.activeBlue : Colors.transparent,
            child: Row(children: [
              Text(label),
              const Spacer(),
              ProgrammeRowButtons(
                rowIndex: rowIndex,
                deckKey: deckKey,
                selected: selected,
                onDelete: onDelete,
                isLive: isLive,
                goLive: goLive,
              )
            ]),
          ),
        ),
        const Divider(
          color: CupertinoColors.darkBackgroundGray,
          height: 0,
          thickness: 1,
        ),
      ],
    );
  }
}

class ProgrammePanel extends StatefulWidget {
  final Stream<Programme> updateStream;
  final StreamSink<Programme> updateStreamSink;
  final Stream<DeckKey?> previewStream;
  final StreamSink<DeckKey?> previewStreamSink;
  final Stream<Message> liveStream;
  final StreamSink<Message> liveStreamSink;

  const ProgrammePanel({
    super.key,
    required this.updateStream,
    required this.updateStreamSink,
    required this.previewStream,
    required this.previewStreamSink,
    required this.liveStream,
    required this.liveStreamSink,
  });

  @override
  createState() => ProgrammePanelState();
}

class ProgrammePanelState extends State<ProgrammePanel> {
  var programme = Programme.new_();

  DeckKey? previewDeck;
  Deck? liveDeck;

  late final StreamSubscription<Programme> _updateStreamSubscription;
  late final StreamSubscription<DeckKey?> _previewStreamSubscription;
  late final StreamSubscription<Message> _liveStreamSubscription;

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
              style: Theme.of(context).primaryTextTheme.headlineSmall,
            ),
            const Spacer(),
            OpenButton(onOpen: widget.updateStreamSink.add)
                .padding(const EdgeInsets.symmetric(horizontal: 4)),
            SaveButton(programme: programme)
                .padding(const EdgeInsets.symmetric(horizontal: 4)),
            const SizedBox(width: 32),
            Button(
              onTap: () => widget.updateStreamSink.add(
                programme.withDecks(
                  programme.decks.rebuild((builder) {
                    builder.insert(
                      programme.decks
                              .indexWhere((deck) => deck.key == previewDeck) +
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
              child: const Icon(
                CupertinoIcons.add,
                color: CupertinoColors.activeBlue,
              ),
            ).padding(const EdgeInsets.symmetric(horizontal: 4)),
          ],
        ).container(
          padding: const EdgeInsets.all(20),
          color: CupertinoColors.darkBackgroundGray,
        ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: ReorderableList(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    // removing the item at oldIndex will shorten the list by 1.
                    newIndex -= 1;
                  }
                  widget.updateStreamSink.add(
                    programme.withDecks(
                      programme.decks.rebuild((decks) {
                        final element = decks.removeAt(oldIndex);
                        decks.insert(newIndex, element);
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
