import 'dart:async';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:core/pubsub.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:flutter/services.dart';
import 'package:flutter_utils/pubsub_builder.dart';
import 'package:flutter_utils/widget_modifiers.dart';
import 'package:uuid/uuid.dart';

import 'colours.dart';
import 'form.dart';
import 'packed_button_row.dart';

@immutable
class _CommentField extends StatefulWidget {
  final PubSub<(DeckIndex?, UuidValue?)> deckIndex;

  const _CommentField({
    required this.deckIndex,
  });

  @override
  State<StatefulWidget> createState() => _CommentFieldState();
}

class _CommentFieldState extends State<_CommentField> {
  DeckIndex? deckIndex;
  final uuid = const Uuid().v4obj();

  late StreamSubscription<(DeckIndex?, UuidValue?)> deckIndexSubscription;

  void processDeckIndex((DeckIndex?, UuidValue?) update) {
    final (newDeckIndex, source) = update;
    if (source != uuid) {
      setState(() => deckIndex = newDeckIndex);
    }
  }

  @override
  void initState() {
    super.initState();
    deckIndexSubscription = widget.deckIndex.subscribe(processDeckIndex);
  }

  @override
  void didUpdateWidget(covariant _CommentField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deckIndex != oldWidget.deckIndex) {
      deckIndexSubscription.cancel();
      deckIndexSubscription = widget.deckIndex.subscribe(processDeckIndex);
    }
  }

  @override
  void dispose() {
    deckIndexSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deckIndex = this.deckIndex;
    if (deckIndex == null) {
      return Container();
    } else {
      return TextFormField(
        initialValue: deckIndex.deck.comment,
        decoration: InputDecoration.collapsed(
          hintText: deckIndex.deck.label,
          hintStyle: ColourPalette.of(context)
              .headingStyle
              .copyWith(color: ColourPalette.of(context).secondaryForeground),
        ),
        style: ColourPalette.of(context).headingStyle,
        autofocus: false,
        onChanged: (comment) => widget.deckIndex.publish((
          deckIndex.withDeck(
            deckIndex.deck.withComment(comment),
          ),
          uuid
        )),
      );
    }
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
              const TitleChunk(title: 'Title', subtitle: 'Subtitle')),
        ),
        PackedButton(
          child: const Icon(CupertinoIcons.text_aligncenter)
              .padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).active,
          filled: chunk is BodyChunk,
          filledChildColour: ColourPalette.of(context).secondaryBackground,
          onTap: () =>
              onChangeChunk(BodyChunk(minorChunks: [''].toBuiltList())),
        ),
      ].toBuiltList(),
    ).padding_(const EdgeInsets.all(4));
  }
}

@immutable
abstract class _EditingSpecificChunkBody extends StatefulWidget {
  final PubSub<(DeckIndex?, UuidValue?)> deckIndex;
  final int chunkIndex;

  const _EditingSpecificChunkBody({
    required this.deckIndex,
    required this.chunkIndex,
  });
}

abstract class _EditingSpecificChunkBodyState<
    T extends _EditingSpecificChunkBody> extends State<T> {
  DeckIndex? deckIndex;
  final uuid = const Uuid().v4obj();

  late StreamSubscription<(DeckIndex?, UuidValue?)> deckIndexSubscription;

  void processDeckIndex((DeckIndex?, UuidValue?) update) {
    final (newDeckIndex, source) = update;
    if (source == uuid) {
      deckIndex = newDeckIndex;
    } else {
      setState(() => deckIndex = newDeckIndex);
    }
  }

  @override
  void initState() {
    super.initState();
    deckIndexSubscription = widget.deckIndex.subscribe(processDeckIndex);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.deckIndex != oldWidget.deckIndex) {
      deckIndexSubscription.cancel();
      deckIndexSubscription = widget.deckIndex.subscribe(processDeckIndex);
    }
  }

  @override
  void dispose() {
    deckIndexSubscription.cancel();
    super.dispose();
  }

  Chunk? get chunk => deckIndex?.deck.chunks[widget.chunkIndex];

  void onChangeChunk(Chunk chunk) {
    deckIndex = deckIndex!.withDeck(
      deckIndex!.deck.rebuildChunks((chunks) {
        chunks[widget.chunkIndex] = chunk;
      }),
    );
    widget.deckIndex.publish((deckIndex, uuid));
  }

  bool selected({required int slide}) =>
      deckIndex?.index == Index(chunk: widget.chunkIndex, slide: slide);

  void select({required int slide}) {
    if (deckIndex != null) {
      widget.deckIndex.publish((
        deckIndex!.withIndex(Index(
          chunk: widget.chunkIndex,
          slide: slide,
        )),
        null,
      ));
    }
  }
}

@immutable
class _EditingCountdownChunkBody extends _EditingSpecificChunkBody {
  const _EditingCountdownChunkBody({
    required super.deckIndex,
    required super.chunkIndex,
  });

  @override
  createState() => _EditingCountdownChunkBodyState();
}

class _EditingCountdownChunkBodyState
    extends _EditingSpecificChunkBodyState<_EditingCountdownChunkBody> {
  @override
  Widget build(BuildContext context) {
    if (deckIndex == null) {
      return Container();
    } else {
      return BCForm<CountdownChunk>(
        value: chunk as CountdownChunk,
        onChange: onChangeChunk,
        backgroundColour: ColourPalette.of(context).background,
        fields: [
          BCTextFormField(
            label: const Text('Title:'),
            getter: (chunk) => chunk.title,
            setter: (chunk) => chunk.withTitle,
            maxLines: null,
            autofocus: selected(slide: 0),
            onTap: () => select(slide: 0),
          ),
          BCTextFormField(
            label: const Text('Subtitle 1:'),
            getter: (chunk) => chunk.subtitle1,
            setter: (chunk) => chunk.withSubtitle1,
            maxLines: null,
            autofocus: false,
            onTap: () => select(slide: 0),
          ),
          BCTextFormField(
            label: const Text('Subtitle 2:'),
            getter: (chunk) => chunk.subtitle2,
            setter: (chunk) => chunk.withSubtitle2,
            maxLines: null,
            autofocus: false,
            onTap: () => select(slide: 0),
          ),
          BCTextFormField(
            label: const Text('Message:'),
            getter: (chunk) => chunk.message,
            setter: (chunk) => chunk.withMessage,
            maxLines: null,
            autofocus: false,
            onTap: () => select(slide: 0),
          ),
          BCTextFormField(
            label: const Text('When Stopped:'),
            getter: (chunk) => chunk.whenStopped,
            setter: (chunk) => chunk.withWhenStopped,
            maxLines: null,
            autofocus: false,
            onTap: () => select(slide: 0),
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
            onTap: () => select(slide: 0),
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
            onTap: () => select(slide: 0),
          ),
        ],
      ).background(
        selected(slide: 0)
            ? ColourPalette.of(context).secondaryActive
            : ColourPalette.of(context).background,
      );
    }
  }
}

@immutable
class _EditingTitleChunkBody extends _EditingSpecificChunkBody {
  const _EditingTitleChunkBody({
    required super.deckIndex,
    required super.chunkIndex,
  });

  @override
  createState() => _EditingTitleChunkBodyState();
}

class _EditingTitleChunkBodyState
    extends _EditingSpecificChunkBodyState<_EditingTitleChunkBody> {
  @override
  Widget build(BuildContext context) {
    if (deckIndex == null) {
      return Container();
    } else {
      return BCForm<TitleChunk>(
        value: chunk as TitleChunk,
        onChange: onChangeChunk,
        backgroundColour: ColourPalette.of(context).background,
        fields: [
          BCTextFormField(
            label: const Text('Title:'),
            getter: (chunk) => chunk.title,
            setter: (chunk) => chunk.withTitle,
            maxLines: null,
            autofocus: selected(slide: 0),
            onTap: () => select(slide: 0),
          ),
          BCTextFormField(
            label: const Text('Subtitle:'),
            getter: (chunk) => chunk.subtitle,
            setter: (chunk) => chunk.withSubtitle,
            maxLines: null,
            autofocus: false,
            onTap: () => select(slide: 0),
          ),
        ],
      ).background(
        selected(slide: 0)
            ? ColourPalette.of(context).secondaryActive
            : ColourPalette.of(context).background,
      );
    }
  }
}

@immutable
class _EditingBodyChunkBody extends StatefulWidget {
  final PubSub<(DeckIndex?, UuidValue?)> deckIndex;
  final int chunkIndex;

  const _EditingBodyChunkBody({
    required this.deckIndex,
    required this.chunkIndex,
  });

  @override
  State<StatefulWidget> createState() => _EditingBodyChunkBodyState();
}

class _EditingBodyChunkBodyState extends State<_EditingBodyChunkBody> {
  int minorChunksCount = 0;

  late StreamSubscription<(DeckIndex?, UuidValue?)> deckIndexSubscription;

  void processDeckIndex((DeckIndex?, UuidValue?) update) {
    final newMinorChunksCount =
        (update.$1?.deck.chunks[widget.chunkIndex] as BodyChunk)
            .minorChunks
            .length;
    if (minorChunksCount != newMinorChunksCount) {
      setState(() => minorChunksCount = newMinorChunksCount);
    }
  }

  @override
  void initState() {
    super.initState();
    deckIndexSubscription = widget.deckIndex.subscribe(processDeckIndex);
  }

  @override
  void didUpdateWidget(covariant _EditingBodyChunkBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.deckIndex != oldWidget.deckIndex) {
      deckIndexSubscription.cancel();
      deckIndexSubscription = widget.deckIndex.subscribe(processDeckIndex);
    }
  }

  @override
  void dispose() {
    deckIndexSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(minorChunksCount, (minorChunkIndex) {
        return _EditingMinorChunk(
          deckIndex: widget.deckIndex,
          chunkIndex: widget.chunkIndex,
          minorChunkIndex: minorChunkIndex,
        ).padding(const EdgeInsets.symmetric(vertical: 0.5));
      }).toList(),
    );
  }
}

@immutable
class _EditingMinorChunkOperations {
  final void Function(DeckIndex) onChange;

  const _EditingMinorChunkOperations({
    required this.onChange,
  });

  void moveUp(DeckIndex deckIndex) {
    if (deckIndex.index.slide > 0) {
      onChange(deckIndex.withIndex(Index(
        chunk: deckIndex.index.chunk,
        slide: deckIndex.index.slide - 1,
      )));
    } else if (deckIndex.index.chunk > 0) {
      final chunk = deckIndex.index.chunk - 1;
      onChange(deckIndex.withIndex(Index(
        chunk: chunk,
        slide: deckIndex.deck.chunks[chunk].slides.length - 1,
      )));
    }
  }

  void moveDown(DeckIndex deckIndex) {
    if (deckIndex.index.slide <
        deckIndex.deck.chunks[deckIndex.index.chunk].slides.length - 1) {
      onChange(deckIndex.withIndex(Index(
        chunk: deckIndex.index.chunk,
        slide: deckIndex.index.slide + 1,
      )));
    } else if (deckIndex.index.chunk < deckIndex.deck.chunks.length - 1) {
      onChange(deckIndex.withIndex(Index(
        chunk: deckIndex.index.chunk + 1,
        slide: 0,
      )));
    }
  }

  void delete(DeckIndex deckIndex) {
    final chunk = deckIndex.chunk as BodyChunk;

    if (deckIndex.chunk.slides.length > 1) {
      onChange(deckIndex.withDeck(
        deckIndex.deck.rebuildChunks((chunks) {
          chunks[deckIndex.index.chunk] =
              chunk.rebuildMinorChunks((minorChunks) {
            minorChunks.removeAt(deckIndex.index.slide);
          });
        }),
      ));
    } else {
      onChange(deckIndex.withDeck(
        deckIndex.deck.rebuildChunks((chunks) {
          chunks.removeAt(deckIndex.index.chunk);
        }),
      ));
    }
  }

  void splitMinorChunk(
    DeckIndex deckIndex, {
    required TextSelection selection,
  }) {
    final chunk = deckIndex.chunk as BodyChunk;

    onChange(DeckIndex(
      deck: deckIndex.deck.rebuildChunks((chunks) {
        chunks[deckIndex.index.chunk] = chunk.rebuildMinorChunks(
          (minorChunksBuilder) {
            minorChunksBuilder.replaceRange(
              deckIndex.index.slide,
              deckIndex.index.slide + 1,
              [
                chunk.minorChunks[deckIndex.index.slide]
                    .substring(0, selection.baseOffset)
                    .trim(),
                chunk.minorChunks[deckIndex.index.slide]
                    .substring(selection.baseOffset)
                    .trim(),
              ],
            );
          },
        );
      }),
      index: Index(
        chunk: deckIndex.index.chunk,
        slide: deckIndex.index.slide + 1,
      ),
    ));
  }

  void splitMajorChunk(
    DeckIndex deckIndex, {
    required TextSelection selection,
  }) {
    final chunk = deckIndex.chunk as BodyChunk;

    onChange(DeckIndex(
      deck: deckIndex.deck.rebuildChunks(
        (chunks) {
          chunks.replaceRange(
            deckIndex.index.chunk,
            deckIndex.index.chunk + 1,
            [
              BodyChunk(
                minorChunks:
                    chunk.minorChunks.sublist(0, deckIndex.index.slide).rebuild(
                  (builder) {
                    if (selection.baseOffset > 0) {
                      builder.add(chunk.minorChunks[deckIndex.index.slide]
                          .substring(0, selection.baseOffset)
                          .trim());
                    }
                  },
                ),
              ),
              BodyChunk(
                minorChunks: chunk.minorChunks
                    .sublist(deckIndex.index.slide + 1)
                    .rebuild(
                  (builder) {
                    builder.insert(
                      0,
                      chunk.minorChunks[deckIndex.index.slide]
                          .substring(selection.baseOffset)
                          .trim(),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      index: Index(chunk: deckIndex.index.chunk + 1, slide: 0),
    ));
  }

  void mergeWithPrevious(DeckIndex deckIndex) {
    final chunk = deckIndex.chunk as BodyChunk;

    if (deckIndex.index.slide == 0) {
      if (deckIndex.index.chunk != 0) {
        final previousChunk = deckIndex.deck.chunks[deckIndex.index.chunk - 1];
        if (previousChunk is BodyChunk) {
          onChange(DeckIndex(
            deck: deckIndex.deck.rebuildChunks(
              (chunks) {
                chunks.replaceRange(
                  deckIndex.index.chunk - 1,
                  deckIndex.index.chunk + 1,
                  [
                    BodyChunk(
                      minorChunks:
                          previousChunk.minorChunks + chunk.minorChunks,
                    ),
                  ],
                );
              },
            ),
            index: Index(
              chunk: deckIndex.index.chunk - 1,
              slide: previousChunk.minorChunks.length,
            ),
          ));
        }
      }
    } else {
      onChange(DeckIndex(
        deck: deckIndex.deck.rebuildChunks((chunks) {
          chunks[deckIndex.index.chunk] = chunk.rebuildMinorChunks(
            (minorChunksBuilder) {
              minorChunksBuilder.replaceRange(
                deckIndex.index.slide - 1,
                deckIndex.index.slide + 1,
                [
                  '${chunk.minorChunks[deckIndex.index.slide - 1]}\n'
                      '${chunk.minorChunks[deckIndex.index.slide]}',
                ],
              );
            },
          );
        }),
        index: Index(
          chunk: deckIndex.index.chunk,
          slide: deckIndex.index.slide - 1,
        ),
      ));
    }
  }

  void mergeWithNext(DeckIndex deckIndex) {
    final chunk = deckIndex.chunk as BodyChunk;

    if (deckIndex.index.slide == chunk.minorChunks.length - 1) {
      if (deckIndex.index.chunk != deckIndex.deck.chunks.length - 1) {
        final nextChunk = deckIndex.deck.chunks[deckIndex.index.chunk + 1];
        if (nextChunk is BodyChunk) {
          onChange(deckIndex.withDeck(
            deckIndex.deck.rebuildChunks((chunks) {
              chunks.replaceRange(
                deckIndex.index.chunk,
                deckIndex.index.chunk + 2,
                [
                  BodyChunk(
                    minorChunks: chunk.minorChunks + nextChunk.minorChunks,
                  ),
                ],
              );
            }),
          ));
        }
      }
    } else {
      onChange(deckIndex.withDeck(
        deckIndex.deck.rebuildChunks((chunks) {
          chunks[deckIndex.index.chunk] = chunk.rebuildMinorChunks(
            (minorChunksBuilder) {
              minorChunksBuilder.replaceRange(
                deckIndex.index.slide,
                deckIndex.index.slide + 2,
                [
                  '${chunk.minorChunks[deckIndex.index.slide]}\n'
                      '${chunk.minorChunks[deckIndex.index.slide + 1]}',
                ],
              );
            },
          );
        }),
      ));
    }
  }
}

@immutable
class _EditingMinorChunk extends _EditingSpecificChunkBody {
  final int minorChunkIndex;

  const _EditingMinorChunk({
    required super.deckIndex,
    required super.chunkIndex,
    required this.minorChunkIndex,
  });

  @override
  createState() => _EditingMinorChunkState();
}

class _EditingMinorChunkState
    extends _EditingSpecificChunkBodyState<_EditingMinorChunk> {
  final controller = TextEditingController();
  final focusNode = FocusNode();

  void gainFocus() {
    select(slide: widget.minorChunkIndex);
  }

  @override
  void processDeckIndex((DeckIndex?, UuidValue?) update) {
    super.processDeckIndex(update);
    final (_, source) = update;
    if (deckIndex != null && source != uuid) {
      final minorChunks =
          (deckIndex!.deck.chunks[widget.chunkIndex] as BodyChunk).minorChunks;
      if (widget.minorChunkIndex < minorChunks.length) {
        controller.text = minorChunks[widget.minorChunkIndex];
      }
    }
  }

  @override
  void initState() {
    super.initState();

    focusNode.addListener(gainFocus);
  }

  @override
  void didUpdateWidget(covariant _EditingMinorChunk oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (selected(slide: widget.minorChunkIndex)) {
      focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    focusNode.removeListener(gainFocus);

    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (deckIndex == null) {
      return Container();
    } else {
      final operations = _EditingMinorChunkOperations(
        onChange: (newDeckIndex) =>
            widget.deckIndex.publish((newDeckIndex, null)),
      );
      return CupertinoTextFormFieldRow(
        padding: const EdgeInsets.all(2),
        controller: controller,
        focusNode: focusNode,
        style: ColourPalette.of(context).bodyStyle,
        autofocus: selected(slide: widget.minorChunkIndex),
        maxLines: null,
        onChanged: (text) {
          onChangeChunk((chunk as BodyChunk).rebuildMinorChunks(
            (minorChunksBuilder) =>
                minorChunksBuilder[widget.minorChunkIndex] = text,
          ));
        },
        cursorColor: ColourPalette.of(context).foreground,
      ).callbackShortcuts(bindings: {
        const SingleActivator(
          LogicalKeyboardKey.arrowUp,
          alt: true,
        ): () {
          if (deckIndex != null) {
            operations.moveUp(deckIndex!);
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.arrowDown,
          alt: true,
        ): () {
          if (deckIndex != null) {
            operations.moveDown(deckIndex!);
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.backspace,
          alt: true,
          shift: true,
        ): () {
          if (deckIndex != null) {
            operations.delete(deckIndex!);
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.delete,
          alt: true,
          shift: true,
        ): () {
          if (deckIndex != null) {
            operations.delete(deckIndex!);
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.enter,
          alt: true,
        ): () {
          if (deckIndex != null) {
            operations.splitMinorChunk(
              deckIndex!,
              selection: controller.selection,
            );
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.enter,
          alt: true,
          shift: true,
        ): () {
          if (deckIndex != null) {
            operations.splitMajorChunk(
              deckIndex!,
              selection: controller.selection,
            );
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.backspace,
          alt: true,
        ): () {
          if (deckIndex != null) {
            operations.mergeWithPrevious(
              deckIndex!,
            );
          }
        },
        const SingleActivator(
          LogicalKeyboardKey.delete,
          alt: true,
        ): () {
          if (deckIndex != null) {
            operations.mergeWithNext(
              deckIndex!,
            );
          }
        },
      }).background(selected(slide: widget.minorChunkIndex)
          ? ColourPalette.of(context).secondaryActive
          : ColourPalette.of(context).background);
    }
  }
}

@immutable
class _EditingChunkBody extends StatefulWidget {
  final PubSub<(DeckIndex?, UuidValue?)> deckIndex;
  final int chunkIndex;

  const _EditingChunkBody({
    required this.deckIndex,
    required this.chunkIndex,
  });

  @override
  State<StatefulWidget> createState() => _EditingChunkBodyState();
}

class _EditingChunkBodyState extends State<_EditingChunkBody> {
  Type? chunkType;

  late StreamSubscription<(DeckIndex?, UuidValue?)> deckIndexSubscription;

  void processDeckIndex((DeckIndex?, UuidValue?) update) {
    final newChunkType = update.$1?.deck.chunks[widget.chunkIndex].runtimeType;
    if (chunkType != newChunkType) {
      setState(() => chunkType = newChunkType);
    }
  }

  @override
  void initState() {
    super.initState();
    deckIndexSubscription = widget.deckIndex.subscribe(processDeckIndex);
  }

  @override
  void didUpdateWidget(covariant _EditingChunkBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.deckIndex != oldWidget.deckIndex) {
      deckIndexSubscription.cancel();
      deckIndexSubscription = widget.deckIndex.subscribe(processDeckIndex);
    }
  }

  @override
  void dispose() {
    deckIndexSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (chunkType == CountdownChunk) {
      return _EditingCountdownChunkBody(
        deckIndex: widget.deckIndex,
        chunkIndex: widget.chunkIndex,
      );
    } else if (chunkType == TitleChunk) {
      return _EditingTitleChunkBody(
        deckIndex: widget.deckIndex,
        chunkIndex: widget.chunkIndex,
      );
    } else if (chunkType == BodyChunk) {
      return _EditingBodyChunkBody(
        deckIndex: widget.deckIndex,
        chunkIndex: widget.chunkIndex,
      );
    } else {
      return const Text('Unknown chunk type');
    }
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
  final PubSub<(DeckIndex?, UuidValue?)> deckIndex;
  final int chunkIndex;

  const _EditingChunk({
    super.key,
    required this.deckIndex,
    required this.chunkIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      PubSubBuilder(
          pubSub: deckIndex,
          builder: (context, update) {
            final deckIndex = update?.$1;
            if (deckIndex == null) {
              return Container();
            } else {
              final chunk = deckIndex.deck.chunks[chunkIndex];
              onChangeChunk(chunk) => this.deckIndex.publish((
                    deckIndex.withDeck(
                      deckIndex.deck.rebuildChunks(
                        (chunksBuilder) => chunksBuilder[chunkIndex] = chunk,
                      ),
                    ),
                    null,
                  ));
              return Row(children: [
                _ChunkTypeRadio(
                  chunk: chunk,
                  onChangeChunk: onChangeChunk,
                ),
                const Spacer(),
                _EditingChunkSpecificButtons(
                  chunk: chunk,
                  onChangeChunk: (chunk) => onChangeChunk(chunk),
                ),
                PackedButtonRow(
                  buttons: [
                    PackedButton(
                      child: const Icon(CupertinoIcons.delete_solid)
                          .padding(const EdgeInsets.all(1)),
                      colour: ColourPalette.of(context).danger,
                      filledChildColour:
                          ColourPalette.of(context).secondaryBackground,
                      onTap: () => this.deckIndex.publish((
                        deckIndex.withDeck(
                          deckIndex.deck.rebuildChunks(
                            (chunks) => chunks.removeAt(chunkIndex),
                          ),
                        ),
                        null,
                      )),
                    ),
                    PackedButton(
                      child: const Icon(CupertinoIcons.arrow_up_arrow_down)
                          .padding(const EdgeInsets.all(1)),
                      colour: ColourPalette.of(context).active,
                      filledChildColour:
                          ColourPalette.of(context).secondaryBackground,
                      wrapper: (child) => ReorderableDragStartListener(
                        index: chunkIndex,
                        child: child,
                      ),
                    ),
                  ].toBuiltList(),
                  padding: const EdgeInsets.all(1),
                ).padding_(const EdgeInsets.all(4)),
              ]).background(ColourPalette.of(context).secondaryBackground);
            }
          }),
      _EditingChunkBody(
        deckIndex: deckIndex,
        chunkIndex: chunkIndex,
      ),
    ]);
  }
}

@immutable
class EditingDeckPanel extends StatefulWidget {
  final PubSub<(DeckIndex?, UuidValue?)> deckIndex;

  const EditingDeckPanel({
    super.key,
    required this.deckIndex,
  });

  @override
  createState() => _EditingDeckPanelState();
}

class _EditingDeckPanelState extends State<EditingDeckPanel> {
  DeckIndex? nonStateDeckIndex;

  int chunkCount = 0;

  late StreamSubscription<(DeckIndex?, UuidValue?)> _deckIndexSubscription;

  void updateDeckIndex((DeckIndex?, UuidValue?) event) {
    final (newDeckIndex, _) = event;
    nonStateDeckIndex = newDeckIndex;

    final newChunkCount = newDeckIndex?.deck.chunks.length ?? 0;
    if (chunkCount != newChunkCount) {
      setState(() => chunkCount = newChunkCount);
    }
  }

  @override
  void initState() {
    super.initState();
    _deckIndexSubscription = widget.deckIndex.subscribe(updateDeckIndex);
  }

  @override
  void didUpdateWidget(covariant EditingDeckPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.deckIndex != oldWidget.deckIndex) {
      _deckIndexSubscription.cancel();
      _deckIndexSubscription = widget.deckIndex.subscribe(updateDeckIndex);
    }
  }

  @override
  void dispose() {
    _deckIndexSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        _CommentField(deckIndex: widget.deckIndex).expanded(),
        PubSubBuilder(
            pubSub: widget.deckIndex,
            builder: (context, update) {
              final deckIndex = update?.$1;
              if (deckIndex == null) {
                return Container();
              } else {
                return PackedButtonRow(
                  buttons: [
                    PackedButton(
                      child: const Icon(CupertinoIcons.add)
                          .padding(const EdgeInsets.all(4)),
                      colour: ColourPalette.of(context).active,
                      filledChildColour:
                          ColourPalette.of(context).secondaryBackground,
                      onTap: () => widget.deckIndex.publish(
                        (
                          deckIndex.withDeck(
                            deckIndex.deck.rebuildChunks(
                              (chunksBuilder) {
                                chunksBuilder.insert(
                                  min(deckIndex.index.chunk + 1,
                                      chunksBuilder.length),
                                  BodyChunk(minorChunks: [''].toBuiltList()),
                                );
                              },
                            ),
                          ),
                          null
                        ),
                      ),
                    )
                  ].toBuiltList(),
                );
              }
            }),
      ]).padding(const EdgeInsets.all(16)),
      ReorderableList(
        itemBuilder: (context, index) {
          return _EditingChunk(
            key: UniqueKey(),
            deckIndex: widget.deckIndex,
            chunkIndex: index,
          );
        },
        itemCount: chunkCount,
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) {
            // removing the item at oldIndex will shorten the list by 1.
            newIndex -= 1;
          }
          final deckIndex = nonStateDeckIndex;
          if (deckIndex != null) {
            widget.deckIndex.publish((
              deckIndex.withDeck(
                deckIndex.deck.rebuildChunks((chunks) {
                  final chunk = chunks.removeAt(oldIndex);
                  chunks.insert(newIndex, chunk);
                }),
              ),
              null,
            ));
          }
        },
      ).expanded(),
    ]).background(ColourPalette.of(context).secondaryBackground);
  }
}
