import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
import 'package:flutter_utils/text_size.dart';
import 'package:flutter_utils/widget_modifiers.dart';

class DeckPanel extends StatelessWidget {
  final StreamSink<Message> stream;
  final BuiltMap<String, DisplaySettings> defaultSettings;
  final DeckIndex deckIndex;

  const DeckPanel({
    super.key,
    required this.stream,
    required this.defaultSettings,
    required this.deckIndex,
    onChange,
  });

  @override
  Widget build(BuildContext context) {
    final lineHeight = textSize(
      "",
      Theme.of(context).textTheme.bodyMedium!,
      double.infinity,
    ).height;
    return ListView(
      children: deckIndex.deck.chunks
          .expandIndexed((chunkIndex, chunk) => [
                ...chunk.slides.expandIndexed(
                  (slideIndex, slide) {
                    final index = Index(chunk: chunkIndex, slide: slideIndex);
                    return [
                      Text(slide.label)
                          .container(
                        padding: EdgeInsets.all(lineHeight / 2),
                        color: Index(chunk: chunkIndex, slide: slideIndex) ==
                                deckIndex.index
                            ? CupertinoColors.activeBlue
                            : Colors.black,
                      )
                          .gestureDetector(onTap: () {
                        stream.add(ShowMessage(
                          defaultSettings: defaultSettings,
                          quiet: true,
                          deckIndex: DeckIndex(
                            deck: deckIndex.deck,
                            index: index,
                          ),
                        ));
                      }),
                      const Divider(
                        color: CupertinoColors.darkBackgroundGray,
                        height: 0,
                        thickness: 1,
                      ),
                    ];
                  },
                ),
                Divider(
                  color: CupertinoColors.darkBackgroundGray,
                  height: lineHeight,
                  thickness: lineHeight,
                ),
              ])
          .toList(growable: false),
    ).background(CupertinoColors.darkBackgroundGray);
  }
}

class EditingDeckPanel extends StatefulWidget {
  final StreamSink<Message> stream;
  final BuiltMap<String, DisplaySettings> defaultSettings;
  final DeckIndex deckIndex;
  final void Function(Deck) onChange;

  const EditingDeckPanel({
    super.key,
    required this.stream,
    required this.defaultSettings,
    required this.deckIndex,
    required this.onChange,
  });

  @override
  createState() => EditingDeckPanelState();
}

class EditingDeckPanelState extends State<EditingDeckPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final deck = widget.deckIndex.deck;
    final index = widget.deckIndex.index;
    final text = deck.editText;

    final cursorOffset = deck.chunks.isEmpty
        ? 0
        : deck.chunks
                .sublist(0, index.chunk)
                .map(
                  (chunk) =>
                      chunk.slides
                          .map((slide) => slide.editText.length + 2)
                          .sum +
                      3,
                )
                .sum +
            deck.chunks[index.chunk].slides
                .sublist(0, index.slide)
                .map((slide) => slide.editText.length + 2)
                .sum;

    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: cursorOffset,
        extentOffset: cursorOffset,
      ),
    );

    _controller.addListener(() {
      widget.stream.add(ShowMessage(
        defaultSettings: widget.defaultSettings,
        quiet: true,
        deckIndex: DeckIndex(deck: deck, index: _currentIndex),
      ));
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final lineHeight = textSize(
      "",
      Theme.of(context).textTheme.bodyMedium!,
      double.infinity,
    ).height;
    return ListView(children: [
      LayoutBuilder(builder: (context, constraints) {
        return Stack(children: [
          Column(
            children:
                widget.deckIndex.deck.chunks.expandIndexed((chunkIndex, chunk) {
              return <Iterable<Widget>>[
                chunk.slides.expandIndexed((slideIndex, slide) {
                  return <Widget>[
                    Container(
                      height: textSize(
                            slide.editText,
                            Theme.of(context).textTheme.bodyMedium!,
                            constraints.maxWidth,
                          ).height +
                          lineHeight,
                      color: Index(chunk: chunkIndex, slide: slideIndex) ==
                              widget.deckIndex.index
                          ? CupertinoColors.activeBlue
                          : Colors.black,
                    ),
                    const Divider(
                      color: CupertinoColors.darkBackgroundGray,
                      height: 0,
                      thickness: 1,
                    ),
                  ];
                }),
                [
                  Divider(
                    color: CupertinoColors.darkBackgroundGray,
                    height: lineHeight,
                    thickness: lineHeight,
                  )
                ],
              ].expand((element) => element);
            }).toList(growable: false),
          ),
          CupertinoTextFormFieldRow(
            padding: const EdgeInsets.all(2),
            controller: _controller,
            style: Theme.of(context).textTheme.bodyMedium,
            autofocus: true,
            maxLines: null,
            onChanged: (text) {
              widget.onChange(Deck.parse(
                key: widget.deckIndex.deck.key,
                displaySettings: widget.deckIndex.deck.displaySettings,
                comment: widget.deckIndex.deck.comment,
                text: text.replaceAll('\r\n', '\n'),
              ));
            },
            cursorColor: Colors.white,
          ),
        ]);
      }),
    ]).background(CupertinoColors.darkBackgroundGray);
  }

  Index get _currentIndex {
    if (_controller.selection.baseOffset < 0) {
      return Index.zero;
    }
    final majorBreaks = "\n\n\n".allMatches(
      _controller.text.substring(
        0,
        _controller.selection.baseOffset,
      ),
    );
    final minorBreaks = "\n\n".allMatches(
      _controller.text.substring(
        majorBreaks.isNotEmpty ? majorBreaks.last.end : 0,
        _controller.selection.baseOffset,
      ),
    );
    var chunk = majorBreaks.length;
    var slide = minorBreaks.length;
    if (chunk < widget.deckIndex.deck.chunks.length &&
        slide < widget.deckIndex.deck.chunks[chunk].slides.length) {
      return Index(chunk: chunk, slide: slide);
    } else {
      return const Index(chunk: 0, slide: 0);
    }
  }
}

class ConditionalEditingDeckPanel extends StatelessWidget {
  final StreamSink<Message> stream;
  final BuiltMap<String, DisplaySettings> defaultSettings;
  final DeckIndex deckIndex;
  final bool editing;
  final void Function(Deck) onChange;

  const ConditionalEditingDeckPanel({
    super.key,
    required this.stream,
    required this.defaultSettings,
    required this.deckIndex,
    required this.editing,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return (editing ? EditingDeckPanel.new : DeckPanel.new)(
      stream: stream,
      defaultSettings: defaultSettings,
      deckIndex: deckIndex,
      onChange: onChange,
    );
  }
}
