import 'dart:async';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:core/music.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
import 'package:flutter/services.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'colours.dart';
import 'form.dart';
import 'music_editor.dart';
import 'packed_button_row.dart';

@immutable
class _CommentField extends StatefulWidget {
  final Deck deck;
  final void Function(Deck) onChanged;

  const _CommentField({
    super.key,
    required this.deck,
    required this.onChanged,
  });

  @override
  createState() => _CommentFieldState();
}

class _CommentFieldState extends State<_CommentField> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller.text = widget.deck.comment;
  }

  @override
  void didUpdateWidget(covariant _CommentField oldWidget) {
    super.didUpdateWidget(oldWidget);

    controller.text = widget.deck.comment;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration.collapsed(
        hintText: widget.deck.label,
        hintStyle: ColourPalette.of(context)
            .headingStyle
            .copyWith(color: ColourPalette.of(context).secondaryForeground),
      ),
      style: ColourPalette.of(context).headingStyle,
      autofocus: false,
      onChanged: (comment) => widget.onChanged(
        widget.deck.withComment(comment),
      ),
    );
  }
}

@immutable
class _ChunkTypeRadio extends StatelessWidget {
  final Chunk chunk;
  final void Function(Chunk) onChangeChunk;

  const _ChunkTypeRadio({required this.chunk, required this.onChangeChunk});

  @override
  Widget build(BuildContext context) {
    return PackedButtonRow(
      buttons: [
        PackedButton(
          child:
              const Icon(CupertinoIcons.clock).padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).active,
          filled: chunk is CountdownChunk,
          filledChildColour: ColourPalette.of(context).secondaryBackground,
          onTap: () => onChangeChunk(CountdownChunk.default_),
        ),
        PackedButton(
          child: const Icon(CupertinoIcons.textformat)
              .padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).active,
          filled: chunk is TitleChunk,
          filledChildColour: ColourPalette.of(context).secondaryBackground,
          onTap: () => onChangeChunk(
            const TitleChunk(title: 'Title', subtitle: 'Subtitle'),
          ),
        ),
        PackedButton(
          child: const Icon(CupertinoIcons.text_aligncenter)
              .padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).active,
          filled: chunk is BodyChunk,
          filledChildColour: ColourPalette.of(context).secondaryBackground,
          onTap: () => onChangeChunk(
            BodyChunk(minorChunks: [''].toBuiltList()),
          ),
        ),
        PackedButton(
          child: const Icon(CupertinoIcons.music_note_2)
              .padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).active,
          filled: chunk is MusicChunk,
          filledChildColour: ColourPalette.of(context).secondaryBackground,
          onTap: () => onChangeChunk(
            MusicChunk(
              minorChunks: [
                Stave(<Glyph>[const TrebleClef()].toBuiltList()),
              ].toBuiltList(),
            ),
          ),
        ),
      ].toBuiltList(),
    ).padding_(const EdgeInsets.all(4));
  }
}

@immutable
class _GenericChunkControls extends StatelessWidget {
  final DeckIndex deckIndex;
  final int chunkIndex;
  final void Function(Deck) onChangeDeck;

  const _GenericChunkControls({
    required this.deckIndex,
    required this.chunkIndex,
    required this.onChangeDeck,
  });

  @override
  Widget build(BuildContext context) {
    return PackedButtonRow(
      buttons: [
        PackedButton(
          child: const Icon(CupertinoIcons.delete_solid)
              .padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).danger,
          filledChildColour: ColourPalette.of(context).secondaryBackground,
          onTap: () => onChangeDeck(
            deckIndex.deck.rebuildChunks(
              (chunksBuilder) => chunksBuilder.removeAt(chunkIndex),
            ),
          ),
        ),
        PackedButton(
          child: const Icon(CupertinoIcons.arrow_up_arrow_down)
              .padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).active,
          filledChildColour: ColourPalette.of(context).secondaryBackground,
          wrapper: (child) => ReorderableDragStartListener(
            index: chunkIndex,
            child: child,
          ),
        ),
      ].toBuiltList(),
      padding: const EdgeInsets.all(1),
    ).padding_(const EdgeInsets.all(4));
  }
}

@immutable
class _EditingChunkBody extends StatelessWidget {
  final DeckIndex deckIndex;
  final Chunk chunk;
  final int chunkIndex;
  final bool Function({required int slide}) selected;
  final void Function(Index) select;
  final void Function(Chunk) onChangeChunk;
  final void Function(Chunk) onChangeChunkPreservingKeys;
  final void Function(Deck) onChangeDeck;

  const _EditingChunkBody({
    required this.deckIndex,
    required this.chunk,
    required this.chunkIndex,
    required this.selected,
    required this.select,
    required this.onChangeChunk,
    required this.onChangeChunkPreservingKeys,
    required this.onChangeDeck,
  });

  @override
  Widget build(BuildContext context) {
    final chunk = this.chunk;
    if (chunk is CountdownChunk) {
      return BCForm<CountdownChunk>(
        value: chunk,
        onChange: onChangeChunkPreservingKeys,
        backgroundColour: ColourPalette.of(context).background,
        fields: [
          BCTextFormField(
            label: const Text('Title:'),
            getter: (chunk) => chunk.title,
            setter: (chunk) => chunk.withTitle,
            maxLines: null,
            autofocus: selected(slide: 0),
            onTap: () => select(Index(chunk: chunkIndex, slide: 0)),
          ),
          BCTextFormField(
            label: const Text('Subtitle 1:'),
            getter: (chunk) => chunk.subtitle1,
            setter: (chunk) => chunk.withSubtitle1,
            maxLines: null,
            autofocus: false,
            onTap: () => select(Index(chunk: chunkIndex, slide: 0)),
          ),
          BCTextFormField(
            label: const Text('Subtitle 2:'),
            getter: (chunk) => chunk.subtitle2,
            setter: (chunk) => chunk.withSubtitle2,
            maxLines: null,
            autofocus: false,
            onTap: () => select(Index(chunk: chunkIndex, slide: 0)),
          ),
          BCTextFormField(
            label: const Text('Message:'),
            getter: (chunk) => chunk.message,
            setter: (chunk) => chunk.withMessage,
            maxLines: null,
            autofocus: false,
            onTap: () => select(Index(chunk: chunkIndex, slide: 0)),
          ),
          BCTextFormField(
            label: const Text('When Stopped:'),
            getter: (chunk) => chunk.whenStopped,
            setter: (chunk) => chunk.withWhenStopped,
            maxLines: null,
            autofocus: false,
            onTap: () => select(Index(chunk: chunkIndex, slide: 0)),
          ),
          BCTextFormField(
            label: const Text('Countdown to:'),
            getter: (chunk) => chunk.countdownTo.toIso8601String(),
            setter: (chunk) => (text) {
              var dateTime = DateTime.tryParse(text);
              if (dateTime == null) {
                return null;
              }
              return chunk.withCountdownTo(dateTime);
            },
            maxLines: null,
            autofocus: false,
            onTap: () => select(Index(chunk: chunkIndex, slide: 0)),
          ),
          BCTextFormField(
            label: const Text('Stop at T-'),
            getter: (chunk) => ''
                '${(chunk.stopAt.inHours).toString().padLeft(2, '0')}:'
                '${(chunk.stopAt.inMinutes % 60).toString().padLeft(2, '0')}:'
                '${(chunk.stopAt.inSeconds % 60).toString().padLeft(2, '0')}',
            setter: (chunk) => (text) {
              final match = RegExp(r'(^\d+):(\d+):(\d+)$').firstMatch(text);
              if (match == null) {
                return null;
              }
              return chunk.withStopAt(
                Duration(
                  hours: int.parse(match.group(1)!),
                  minutes: int.parse(match.group(2)!),
                  seconds: int.parse(match.group(3)!),
                ),
              );
            },
            maxLines: null,
            autofocus: false,
            onTap: () => select(Index(chunk: chunkIndex, slide: 0)),
          ),
        ],
      ).background(
        selected(slide: 0)
            ? ColourPalette.of(context).secondaryActive
            : ColourPalette.of(context).background,
      );
    } else if (chunk is TitleChunk) {
      return BCForm<TitleChunk>(
        value: chunk,
        onChange: onChangeChunkPreservingKeys,
        backgroundColour: ColourPalette.of(context).background,
        fields: [
          BCTextFormField(
            label: const Text('Title:'),
            getter: (chunk) => chunk.title,
            setter: (chunk) => chunk.withTitle,
            maxLines: null,
            autofocus: selected(slide: 0),
            onTap: () => select(Index(chunk: chunkIndex, slide: 0)),
          ),
          BCTextFormField(
            label: const Text('Subtitle:'),
            getter: (chunk) => chunk.subtitle,
            setter: (chunk) => chunk.withSubtitle,
            maxLines: null,
            autofocus: false,
            onTap: () => select(Index(chunk: chunkIndex, slide: 0)),
          ),
        ],
      ).background(
        selected(slide: 0)
            ? ColourPalette.of(context).secondaryActive
            : ColourPalette.of(context).background,
      );
    } else if (chunk is BodyChunk) {
      return Column(
        children: List.generate(chunk.minorChunks.length, (minorChunkIndex) {
          return _EditingMinorChunk(
            deckIndex: deckIndex,
            chunk: chunk,
            chunkIndex: chunkIndex,
            minorChunkIndex: minorChunkIndex,
            selected: selected(slide: minorChunkIndex),
            select: select,
            onChangeChunk: onChangeChunk,
            onChangeChunkPreservingKeys: onChangeChunkPreservingKeys,
            onChangeDeck: onChangeDeck,
          )
              .background(selected(slide: minorChunkIndex)
                  ? ColourPalette.of(context).secondaryActive
                  : ColourPalette.of(context).background)
              .padding(const EdgeInsets.symmetric(vertical: 0.5));
        }).toList(),
      );
    } else if (chunk is MusicChunk) {
      return Column(
        children: chunk.minorChunks
            .map((stave) => MusicEditor(
                  stave: stave,
                  onChangeStave: (stave) => onChangeChunk(
                    MusicChunk(minorChunks: [stave].toBuiltList()),
                  ),
                ))
            .toList(),
      );
    } else {
      return const Text('Unknown chunk type');
    }
  }
}

@immutable
class _EditingMinorChunk extends StatefulWidget {
  final DeckIndex deckIndex;
  final BodyChunk chunk;
  final int chunkIndex;
  final int minorChunkIndex;
  final bool selected;
  final void Function(Index) select;
  final void Function(Chunk) onChangeChunk;
  final void Function(Chunk) onChangeChunkPreservingKeys;
  final void Function(Deck) onChangeDeck;

  const _EditingMinorChunk({
    required this.deckIndex,
    required this.chunk,
    required this.chunkIndex,
    required this.minorChunkIndex,
    required this.selected,
    required this.select,
    required this.onChangeChunk,
    required this.onChangeChunkPreservingKeys,
    required this.onChangeDeck,
  });

  @override
  createState() => _EditingMinorChunkState();
}

class _EditingMinorChunkState extends State<_EditingMinorChunk> {
  final controller = TextEditingController();
  final focusNode = FocusNode();

  void delete() {
    widget.onChangeChunk(
      widget.chunk.rebuildMinorChunks(
        (minorChunksBuilder) {
          minorChunksBuilder.removeAt(widget.minorChunkIndex);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    controller.text = widget.chunk.minorChunks[widget.minorChunkIndex];
  }

  @override
  void didUpdateWidget(covariant _EditingMinorChunk oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selected) {
      focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTextFormFieldRow(
      padding: const EdgeInsets.all(2),
      controller: controller,
      focusNode: focusNode,
      style: ColourPalette.of(context).bodyStyle,
      autofocus: widget.selected,
      maxLines: null,
      onChanged: (text) {
        widget.onChangeChunkPreservingKeys(
          widget.chunk.rebuildMinorChunks(
            (minorChunksBuilder) =>
                minorChunksBuilder[widget.minorChunkIndex] = text,
          ),
        );
      },
      onTap: () => widget.select(
        Index(
          chunk: widget.chunkIndex,
          slide: widget.minorChunkIndex,
        ),
      ),
      cursorColor: ColourPalette.of(context).foreground,
    ).callbackShortcuts(bindings: {
      const SingleActivator(
        LogicalKeyboardKey.arrowUp,
        alt: true,
      ): () {
        if (widget.minorChunkIndex > 0) {
          widget.select(
            Index(
              chunk: widget.chunkIndex,
              slide: widget.minorChunkIndex - 1,
            ),
          );
        }
      },
      const SingleActivator(
        LogicalKeyboardKey.arrowDown,
        alt: true,
      ): () {
        if (widget.minorChunkIndex < widget.chunk.minorChunks.length - 1) {
          widget.select(
            Index(
              chunk: widget.chunkIndex,
              slide: widget.minorChunkIndex + 1,
            ),
          );
        }
      },
      const SingleActivator(
        LogicalKeyboardKey.backspace,
        alt: true,
      ): delete,
      const SingleActivator(
        LogicalKeyboardKey.delete,
        alt: true,
      ): delete,
      const SingleActivator(
        LogicalKeyboardKey.enter,
        alt: true,
      ): () {
        widget.onChangeChunk(
          widget.chunk.rebuildMinorChunks(
            (minorChunksBuilder) {
              minorChunksBuilder.replaceRange(
                widget.minorChunkIndex,
                widget.minorChunkIndex + 1,
                [
                  controller.text
                      .substring(0, controller.selection.baseOffset)
                      .trim(),
                  controller.text
                      .substring(controller.selection.baseOffset)
                      .trim(),
                ],
              );
            },
          ),
        );
        widget.select(
          Index(
            chunk: widget.chunkIndex,
            slide: widget.minorChunkIndex + 1,
          ),
        );
      },
      const SingleActivator(
        LogicalKeyboardKey.enter,
        alt: true,
        shift: true,
      ): () {
        widget.onChangeDeck(
          widget.deckIndex.deck.rebuildChunks(
            (chunksBuilder) {
              chunksBuilder.replaceRange(
                widget.deckIndex.index.chunk,
                widget.deckIndex.index.chunk + 1,
                [
                  BodyChunk(
                    minorChunks: widget.chunk.minorChunks
                        .sublist(0, widget.minorChunkIndex)
                        .rebuild(
                      (builder) {
                        if (controller.selection.baseOffset > 0) {
                          builder.add(controller.text
                              .substring(0, controller.selection.baseOffset));
                        }
                      },
                    ),
                  ),
                  BodyChunk(
                    minorChunks: widget.chunk.minorChunks
                        .sublist(widget.minorChunkIndex + 1)
                        .rebuild(
                      (builder) {
                        if (controller.selection.baseOffset <
                            controller.text.length) {
                          builder.insert(
                            0,
                            controller.text
                                .substring(controller.selection.baseOffset),
                          );
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
        widget.select(
          Index(chunk: widget.deckIndex.index.chunk + 1, slide: 0),
        );
      },
      const SingleActivator(
        LogicalKeyboardKey.backspace,
        alt: true,
        shift: true,
      ): () {
        if (widget.minorChunkIndex == 0) {
          if (widget.deckIndex.index.chunk != 0) {
            final previousChunk =
                widget.deckIndex.deck.chunks[widget.deckIndex.index.chunk - 1];
            if (previousChunk is BodyChunk) {
              widget.onChangeDeck(
                widget.deckIndex.deck.rebuildChunks(
                  (chunksBuilder) {
                    chunksBuilder.replaceRange(
                      widget.deckIndex.index.chunk - 1,
                      widget.deckIndex.index.chunk + 1,
                      [
                        BodyChunk(
                          minorChunks: previousChunk.minorChunks +
                              widget.chunk.minorChunks,
                        ),
                      ],
                    );
                  },
                ),
              );
              widget.select(
                Index(
                  chunk: widget.deckIndex.index.chunk - 1,
                  slide: previousChunk.minorChunks.length,
                ),
              );
            }
          }
        } else {
          widget.onChangeChunk(
            widget.chunk.rebuildMinorChunks(
              (minorChunksBuilder) {
                minorChunksBuilder.replaceRange(
                  widget.minorChunkIndex - 1,
                  widget.minorChunkIndex + 1,
                  [
                    '${widget.chunk.minorChunks[widget.minorChunkIndex - 1]}\n'
                        '${widget.chunk.minorChunks[widget.minorChunkIndex]}',
                  ],
                );
              },
            ),
          );
          widget.select(
            Index(
              chunk: widget.chunkIndex,
              slide: widget.minorChunkIndex - 1,
            ),
          );
        }
      },
      const SingleActivator(
        LogicalKeyboardKey.delete,
        alt: true,
        shift: true,
      ): () {
        if (widget.minorChunkIndex == widget.chunk.minorChunks.length - 1) {
          if (widget.deckIndex.index.chunk !=
              widget.deckIndex.deck.chunks.length - 1) {
            final nextChunk =
                widget.deckIndex.deck.chunks[widget.deckIndex.index.chunk + 1];
            if (nextChunk is BodyChunk) {
              widget.onChangeDeck(
                widget.deckIndex.deck.rebuildChunks(
                  (chunksBuilder) {
                    chunksBuilder.replaceRange(
                      widget.deckIndex.index.chunk,
                      widget.deckIndex.index.chunk + 2,
                      [
                        BodyChunk(
                          minorChunks:
                              widget.chunk.minorChunks + nextChunk.minorChunks,
                        ),
                      ],
                    );
                  },
                ),
              );
            }
          }
        } else {
          widget.onChangeChunk(
            widget.chunk.rebuildMinorChunks(
              (minorChunksBuilder) {
                minorChunksBuilder.replaceRange(
                  widget.minorChunkIndex,
                  widget.minorChunkIndex + 2,
                  [
                    '${widget.chunk.minorChunks[widget.minorChunkIndex]}\n'
                        '${widget.chunk.minorChunks[widget.minorChunkIndex + 1]}',
                  ],
                );
              },
            ),
          );
        }
      },
    });
  }
}

@immutable
class _EditingChunkSpecificButtons extends StatelessWidget {
  final Chunk chunk;
  final void Function(Chunk) onChangeChunk;

  const _EditingChunkSpecificButtons({
    required this.chunk,
    required this.onChangeChunk,
  });

  @override
  Widget build(BuildContext context) {
    final chunk = this.chunk;
    if (chunk is BodyChunk) {
      return PackedButtonRow(
        buttons: [
          PackedButton(
            child:
                const Icon(CupertinoIcons.add).padding(const EdgeInsets.all(1)),
            colour: ColourPalette.of(context).active,
            filledChildColour: ColourPalette.of(context).secondaryBackground,
            onTap: () => onChangeChunk(
              chunk.rebuildMinorChunks(
                (minorChunksBuilder) => minorChunksBuilder.add(''),
              ),
            ),
          ),
        ].toBuiltList(),
        padding: const EdgeInsets.all(1),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class _EditingChunk extends StatelessWidget {
  final DeckIndex deckIndex;
  final int chunkIndex;
  final void Function(Index) select;
  final void Function(Deck) onChangeDeck;
  final void Function(Deck) onChangeDeckPreservingKeys;

  const _EditingChunk({
    super.key,
    required this.deckIndex,
    required this.chunkIndex,
    required this.select,
    required this.onChangeDeck,
    required this.onChangeDeckPreservingKeys,
  });

  Chunk get chunk => deckIndex.deck.chunks[chunkIndex];

  onChangeChunk(chunk) => onChangeDeck(
        deckIndex.deck.rebuildChunks(
          (chunksBuilder) => chunksBuilder[chunkIndex] = chunk,
        ),
      );

  onChangeChunkPreservingKeys(chunk) => onChangeDeckPreservingKeys(
        deckIndex.deck.rebuildChunks(
          (chunksBuilder) => chunksBuilder[chunkIndex] = chunk,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        _ChunkTypeRadio(
          chunk: chunk,
          onChangeChunk: onChangeChunkPreservingKeys,
        ),
        const Spacer(),
        _EditingChunkSpecificButtons(
          chunk: chunk,
          onChangeChunk: onChangeChunk,
        ),
        _GenericChunkControls(
          deckIndex: deckIndex,
          chunkIndex: chunkIndex,
          onChangeDeck: onChangeDeck,
        ),
      ]).background(ColourPalette.of(context).secondaryBackground),
      _EditingChunkBody(
        deckIndex: deckIndex,
        chunk: chunk,
        chunkIndex: chunkIndex,
        selected: ({required slide}) =>
            deckIndex.index == Index(chunk: chunkIndex, slide: slide),
        select: select,
        onChangeChunk: onChangeChunk,
        onChangeChunkPreservingKeys: onChangeChunkPreservingKeys,
        onChangeDeck: onChangeDeck,
      ),
    ]);
  }
}

@immutable
class EditingDeckPanel extends StatefulWidget {
  final StreamSink<Message> stream;
  final BuiltMap<String, DisplaySettings> defaultSettings;
  final DeckIndex deckIndex;
  final void Function(Index) select;
  final void Function(Deck) onChange;

  const EditingDeckPanel({
    super.key,
    required this.stream,
    required this.defaultSettings,
    required this.deckIndex,
    required this.select,
    required this.onChange,
  });

  @override
  createState() => _EditingDeckPanelState();
}

class _EditingDeckPanelState extends State<EditingDeckPanel> {
  final listKey = UniqueKey();
  UniqueKey commentKey = UniqueKey();
  List<UniqueKey> chunkKeys = [];
  Deck? expectedDeck;

  void refreshKeys() {
    if (widget.deckIndex.deck != expectedDeck) {
      commentKey = UniqueKey();
      chunkKeys = List.generate(
        widget.deckIndex.deck.chunks.length,
        (index) => UniqueKey(),
      );
      expectedDeck = widget.deckIndex.deck;
    }
  }

  void onChangePreservingKeys(Deck deck) {
    // Don't need setState because this doesn't require refresh
    expectedDeck = deck;
    widget.onChange(deck);
  }

  @override
  void initState() {
    super.initState();
    refreshKeys();
  }

  @override
  void didUpdateWidget(covariant EditingDeckPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    refreshKeys();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        _CommentField(
          key: commentKey,
          deck: widget.deckIndex.deck,
          onChanged: onChangePreservingKeys,
        ).expanded(),
        PackedButtonRow(
            buttons: [
          PackedButton(
            child:
                const Icon(CupertinoIcons.add).padding(const EdgeInsets.all(4)),
            colour: ColourPalette.of(context).active,
            filledChildColour: ColourPalette.of(context).secondaryBackground,
            onTap: () => widget.onChange(
              widget.deckIndex.deck.rebuildChunks(
                (chunksBuilder) {
                  chunksBuilder.insert(
                    min(widget.deckIndex.index.chunk + 1, chunksBuilder.length),
                    BodyChunk(minorChunks: [''].toBuiltList()),
                  );
                },
              ),
            ),
          )
        ].toBuiltList()),
      ]).padding(const EdgeInsets.all(16)),
      ReorderableList(
        key: listKey,
        itemBuilder: (context, index) {
          return _EditingChunk(
            key: chunkKeys[index],
            deckIndex: widget.deckIndex,
            chunkIndex: index,
            select: widget.select,
            onChangeDeck: widget.onChange,
            onChangeDeckPreservingKeys: onChangePreservingKeys,
          );
        },
        itemCount: widget.deckIndex.deck.chunks.length,
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) {
            // removing the item at oldIndex will shorten the list by 1.
            newIndex -= 1;
          }
          var newDeck = widget.deckIndex.deck.rebuildChunks(
            (chunksBuilder) {
              final chunk = chunksBuilder.removeAt(oldIndex);
              chunksBuilder.insert(newIndex, chunk);
            },
          );
          widget.onChange(newDeck);
        },
      ).expanded(),
    ]).background(ColourPalette.of(context).secondaryBackground);
  }
}
