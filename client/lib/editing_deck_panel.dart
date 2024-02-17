import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:core/pubsub.dart';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:flutter/services.dart';
import 'package:flutter_utils/widget_modifiers.dart';
import 'package:uuid/uuid.dart';

import 'colours.dart';
import 'form2.dart';
import 'packed_button_row.dart';

@immutable
class _CommentField extends StatelessWidget {
  final _DeckIndexEditingController controller;

  const _CommentField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller.commentController,
      decoration: InputDecoration.collapsed(
        hintText: controller.deckIndex.deck.label,
        hintStyle: ColourPalette.of(context)
            .headingStyle
            .copyWith(color: ColourPalette.of(context).secondaryForeground),
      ),
      style: ColourPalette.of(context).headingStyle,
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
          debugLabel: 'Countdown',
          child:
              const Icon(CupertinoIcons.clock).padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).active,
          filled: chunk is CountdownChunk,
          filledChildColour: ColourPalette.of(context).secondaryBackground,
          onTap: () => onChangeChunk(CountdownChunk.default_),
        ),
        PackedButton(
          debugLabel: 'Title',
          child: const Icon(CupertinoIcons.textformat)
              .padding(const EdgeInsets.all(1)),
          colour: ColourPalette.of(context).active,
          filled: chunk is TitleChunk,
          filledChildColour: ColourPalette.of(context).secondaryBackground,
          onTap: () => onChangeChunk(
              const TitleChunk(title: 'Title', subtitle: 'Subtitle')),
        ),
        PackedButton(
          debugLabel: 'Body',
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
class _EditingCountdownChunkBody extends StatelessWidget {
  final _CountdownChunkEditingController controller;

  const _EditingCountdownChunkBody({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: controller.focusNode,
      skipTraversal: true,
      child: BCForm2(
        backgroundColour: ColourPalette.of(context).background,
        fields: [
          BCTextFormField2(
            label: const Text('Title:'),
            controller: controller.titleController,
            maxLines: null,
          ),
          BCTextFormField2(
            label: const Text('Subtitle 1:'),
            controller: controller.subtitle1Controller,
            maxLines: null,
          ),
          BCTextFormField2(
            label: const Text('Subtitle 2:'),
            controller: controller.subtitle2Controller,
            maxLines: null,
          ),
          BCTextFormField2(
            label: const Text('Message:'),
            controller: controller.messageController,
            maxLines: null,
          ),
          BCTextFormField2(
            label: const Text('When Stopped:'),
            controller: controller.whenStoppedController,
            maxLines: null,
          ),
          BCTextFormField2(
            label: const Text('Countdown to:'),
            controller: controller.countdownToController,
            isValid: (text) => DateTime.tryParse(text) != null,
            maxLines: null,
          ),
          BCTextFormField2(
            label: const Text('Stop at T-'),
            controller: controller.stopAtController,
            isValid: (text) =>
                RegExp(r'(^\d+):(\d+):(\d+)$').firstMatch(text) != null,
            maxLines: null,
          ),
        ],
      ),
    ).background(
      controller.focusNode.hasFocus
          ? ColourPalette.of(context).secondaryActive
          : ColourPalette.of(context).background,
    );
  }
}

@immutable
class _EditingTitleChunkBody extends StatelessWidget {
  final _TitleChunkEditingController controller;

  const _EditingTitleChunkBody({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: controller.focusNode,
      skipTraversal: true,
      child: BCForm2(
        backgroundColour: ColourPalette.of(context).background,
        fields: [
          BCTextFormField2(
            label: const Text('Title:'),
            controller: controller.titleController,
            maxLines: null,
          ),
          BCTextFormField2(
            label: const Text('Subtitle:'),
            controller: controller.subtitleController,
            maxLines: null,
          ),
        ],
      ),
    ).background(
      controller.focusNode.hasFocus
          ? ColourPalette.of(context).secondaryActive
          : ColourPalette.of(context).background,
    );
  }
}

@immutable
class _EditingBodyChunkBody extends StatelessWidget {
  final _DeckIndexEditingController deckIndexController;
  final _BodyChunkEditingController controller;

  const _EditingBodyChunkBody({
    required this.deckIndexController,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final operations = _EditingMinorChunkOperations(
      deckIndexController: deckIndexController,
    );
    return Column(
      children: List.generate(
        controller.minorChunkControllers.length,
        (minorChunkIndex) {
          final (controller: controller, focusNode: focusNode) =
              this.controller.minorChunkControllers[minorChunkIndex];
          return CupertinoTextFormFieldRow(
            padding: const EdgeInsets.all(2),
            controller: controller,
            focusNode: focusNode,
            style: ColourPalette.of(context).bodyStyle,
            maxLines: null,
            cursorColor: ColourPalette.of(context).foreground,
          )
              .callbackShortcuts(bindings: {
                const SingleActivator(
                  LogicalKeyboardKey.backspace,
                  alt: true,
                  shift: true,
                ): operations.delete,
                const SingleActivator(
                  LogicalKeyboardKey.delete,
                  alt: true,
                  shift: true,
                ): operations.delete,
                const SingleActivator(
                  LogicalKeyboardKey.enter,
                  alt: true,
                ): operations.splitMinorChunk,
                const SingleActivator(
                  LogicalKeyboardKey.enter,
                  alt: true,
                  shift: true,
                ): operations.splitMajorChunk,
                const SingleActivator(
                  LogicalKeyboardKey.backspace,
                  alt: true,
                ): operations.mergeWithPrevious,
                const SingleActivator(
                  LogicalKeyboardKey.delete,
                  alt: true,
                ): operations.mergeWithNext,
              })
              .background(focusNode.hasFocus
                  ? ColourPalette.of(context).secondaryActive
                  : ColourPalette.of(context).background)
              .padding(const EdgeInsets.symmetric(vertical: 0.5));
        },
      ).toList(),
    );
  }
}

class _DeckIndexEditingController with ChangeNotifier {
  late DeckKey key;
  late BuiltMap<String, OptionalDisplaySettings> displaySettings;
  final commentController = TextEditingController();
  List<_ChunkEditingController> chunkControllers = [];

  _DeckIndexEditingController(DeckIndex deckIndex) {
    this.deckIndex = deckIndex;
    commentController.addListener(notifyListeners);
  }

  @override
  void dispose() {
    commentController.dispose();
    for (final chunkController in chunkControllers) {
      chunkController.dispose();
    }
    super.dispose();
  }

  Deck get deck => Deck(
        key: key,
        displaySettings: displaySettings,
        comment: commentController.text,
        chunks: chunkControllers
            .map((chunkController) => chunkController.chunk)
            .toBuiltList(),
      );

  Index get index =>
      chunkControllers
          .mapIndexed((chunk, chunkController) => chunkController.focusNodes
              .mapIndexed((slide, focusNode) =>
                  focusNode.hasFocus ? Index(chunk: chunk, slide: slide) : null)
              .firstWhereOrNull((index) => index != null))
          .firstWhereOrNull((index) => index != null) ??
      const Index(chunk: 0, slide: 0);

  DeckIndex get deckIndex => DeckIndex(deck: deck, index: index);

  set deckIndex(DeckIndex deckIndex) {
    key = deckIndex.deck.key;
    displaySettings = deckIndex.deck.displaySettings;
    commentController.text = deckIndex.deck.comment;
    for (final chunkController in chunkControllers) {
      chunkController.dispose();
    }
    chunkControllers =
        deckIndex.deck.chunks.map(_ChunkEditingController.new).toList();
    for (final chunkController in chunkControllers) {
      chunkController.addListener(notifyListeners);
    }
  }

  void removeChunkAt(int index) =>
      chunkControllers.removeAt(index)..controller.dispose();

  void insertChunkAt(int index, Chunk chunk, {int? focusIndex}) {
    final controller = _ChunkEditingController(chunk);
    controller.addListener(notifyListeners);
    if (focusIndex != null) {
      controller.focusNodes.elementAt(focusIndex).requestFocus();
    }
    chunkControllers.insert(index, controller);
  }
}

class _ChunkEditingController with ChangeNotifier {
  _ChunkEditingControllerBase controller;

  _ChunkEditingController(Chunk chunk)
      : controller = _ChunkEditingControllerBase(chunk) {
    controller.addListener(notifyListeners);
  }

  Chunk get chunk => controller.chunk;

  set chunk(Chunk newChunk) {
    print('setting chunk $chunk to $newChunk');
    if (chunk.runtimeType == newChunk.runtimeType) {
      controller.unsafeSetChunk(newChunk);
    } else {
      controller = _ChunkEditingControllerBase(newChunk);
      controller.addListener(notifyListeners);
      notifyListeners();
    }
  }

  Iterable<FocusNode> get focusNodes => controller.focusNodes;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

abstract class _ChunkEditingControllerBase with ChangeNotifier {
  Chunk get chunk;

  void unsafeSetChunk(chunk);

  Iterable<FocusNode> get focusNodes;

  @override
  void dispose();

  factory _ChunkEditingControllerBase(Chunk chunk) {
    if (chunk is CountdownChunk) {
      return _CountdownChunkEditingController(chunk);
    } else if (chunk is TitleChunk) {
      return _TitleChunkEditingController(chunk);
    } else if (chunk is BodyChunk) {
      return _BodyChunkEditingController(chunk);
    } else {
      throw ArgumentError.value(chunk, "chunk", "Invalid Type");
    }
  }
}

class _CountdownChunkEditingController
    with ChangeNotifier
    implements _ChunkEditingControllerBase {
  final titleController = TextEditingController();
  final subtitle1Controller = TextEditingController();
  final subtitle2Controller = TextEditingController();
  final messageController = TextEditingController();
  final whenStoppedController = TextEditingController();
  final countdownToController = TextEditingController();
  final stopAtController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void dispose() {
    titleController.dispose();
    subtitle1Controller.dispose();
    subtitle2Controller.dispose();
    messageController.dispose();
    whenStoppedController.dispose();
    countdownToController.dispose();
    stopAtController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  _CountdownChunkEditingController(CountdownChunk chunk) {
    this.chunk = chunk;
    titleController.addListener(notifyListeners);
    subtitle1Controller.addListener(notifyListeners);
    subtitle2Controller.addListener(notifyListeners);
    messageController.addListener(notifyListeners);
    whenStoppedController.addListener(notifyListeners);
    countdownToController.addListener(notifyListeners);
    stopAtController.addListener(notifyListeners);
    focusNode.addListener(notifyListeners);
  }

  @override
  CountdownChunk get chunk {
    final countdownTo =
        DateTime.tryParse(countdownToController.text) ?? DateTime.now();

    final stopAtMatch =
        RegExp(r'(^\d+):(\d+):(\d+)$').firstMatch(stopAtController.text);
    final stopAt = stopAtMatch == null
        ? const Duration()
        : Duration(
            hours: int.parse(stopAtMatch.group(1)!),
            minutes: int.parse(stopAtMatch.group(2)!),
            seconds: int.parse(stopAtMatch.group(3)!),
          );

    return CountdownChunk(
      title: titleController.text,
      subtitle1: subtitle1Controller.text,
      subtitle2: subtitle2Controller.text,
      message: messageController.text,
      whenStopped: whenStoppedController.text,
      countdownTo: countdownTo,
      stopAt: stopAt,
    );
  }

  set chunk(CountdownChunk chunk) {
    titleController.text = chunk.title;
    subtitle1Controller.text = chunk.subtitle1;
    subtitle2Controller.text = chunk.subtitle2;
    messageController.text = chunk.message;
    whenStoppedController.text = chunk.whenStopped;
    countdownToController.text = chunk.countdownTo.toIso8601String();
    stopAtController.text = ''
        '${(chunk.stopAt.inHours).toString().padLeft(2, '0')}:'
        '${(chunk.stopAt.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(chunk.stopAt.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void unsafeSetChunk(chunk) {
    this.chunk = chunk;
  }

  @override
  Iterable<FocusNode> get focusNodes => [focusNode];
}

class _TitleChunkEditingController
    with ChangeNotifier
    implements _ChunkEditingControllerBase {
  final titleController = TextEditingController();
  final subtitleController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void dispose() {
    titleController.dispose();
    subtitleController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  _TitleChunkEditingController(TitleChunk chunk) {
    this.chunk = chunk;
    titleController.addListener(notifyListeners);
    subtitleController.addListener(notifyListeners);
    focusNode.addListener(notifyListeners);
  }

  @override
  TitleChunk get chunk => TitleChunk(
        title: titleController.text,
        subtitle: subtitleController.text,
      );

  set chunk(TitleChunk chunk) {
    titleController.text = chunk.title;
    subtitleController.text = chunk.subtitle;
  }

  @override
  void unsafeSetChunk(chunk) {
    this.chunk = chunk;
  }

  @override
  Iterable<FocusNode> get focusNodes => [focusNode];
}

class _BodyChunkEditingController
    with ChangeNotifier
    implements _ChunkEditingControllerBase {
  late List<({TextEditingController controller, FocusNode focusNode})>
      minorChunkControllers;

  void initWith(BodyChunk chunk) {
    minorChunkControllers = chunk.minorChunks
        .map((minorChunk) => (
              controller: TextEditingController(text: minorChunk)
                ..addListener(notifyListeners),
              focusNode: FocusNode(debugLabel: "Minor Chunk Controller")
                ..addListener(notifyListeners),
            ))
        .toList();
  }

  @override
  void dispose() {
    for (final (controller: controller, focusNode: focusNode)
        in minorChunkControllers) {
      controller.dispose();
      focusNode.dispose();
    }
    super.dispose();
  }

  _BodyChunkEditingController(BodyChunk chunk) {
    initWith(chunk);
  }

  @override
  BodyChunk get chunk => BodyChunk(
        minorChunks: minorChunkControllers
            .map((controller) => controller.controller.text)
            .toBuiltList(),
      );

  set chunk(BodyChunk chunk) {
    for (final (controller: controller, focusNode: focusNode)
        in minorChunkControllers) {
      controller.dispose();
      focusNode.dispose();
    }
    initWith(chunk);
  }

  @override
  void unsafeSetChunk(chunk) {
    this.chunk = chunk;
  }

  @override
  Iterable<FocusNode> get focusNodes =>
      minorChunkControllers.map((controller) => controller.focusNode);

  int? get minorChunkIndex {
    final index = minorChunkControllers.indexWhere(
      (minorChunkController) => minorChunkController.focusNode.hasFocus,
    );
    return index >= 0 ? index : null;
  }

  void removeAt(int index) => minorChunkControllers.removeAt(index)
    ..controller.dispose()
    ..focusNode.dispose();

  void insertAt(int index, {required String text}) =>
      minorChunkControllers.insert(index, (
        controller: TextEditingController(text: text)
          ..addListener(notifyListeners),
        focusNode: FocusNode(debugLabel: "Minor Chunk Controller")
          ..addListener(notifyListeners),
      ));
}

@immutable
class _EditingMinorChunkOperations {
  final _DeckIndexEditingController deckIndexController;

  const _EditingMinorChunkOperations({
    required this.deckIndexController,
  });

  void delete() {
    final index = deckIndexController.index;

    final chunkController =
        deckIndexController.chunkControllers[index.chunk].controller;

    if (chunkController is _BodyChunkEditingController &&
        chunkController.minorChunkControllers.length > 1) {
      final minorChunkIndex = chunkController.minorChunkIndex;
      if (minorChunkIndex != null) {
        chunkController.removeAt(minorChunkIndex);
      }
    } else {
      deckIndexController.removeChunkAt(index.chunk);
    }
    deckIndexController.notifyListeners();
  }

  void splitMinorChunk() {
    for (final chunkControllerWrapper in deckIndexController.chunkControllers) {
      final chunkController = chunkControllerWrapper.controller;
      if (chunkController is _BodyChunkEditingController) {
        final minorChunkIndex = chunkController.minorChunkIndex;
        if (minorChunkIndex != null) {
          final minorChunkController =
              chunkController.minorChunkControllers[minorChunkIndex];
          final text = minorChunkController.controller.text;
          final selection = minorChunkController.controller.selection;
          chunkController.removeAt(minorChunkIndex);
          chunkController.insertAt(
            minorChunkIndex,
            text: text.substring(0, selection.baseOffset).trim(),
          );
          chunkController.insertAt(
            minorChunkIndex + 1,
            text: text.substring(selection.baseOffset).trim(),
          );
        }
      }
    }
    deckIndexController.notifyListeners();
  }

  void splitMajorChunk() {
    final index = deckIndexController.index;

    final chunkController =
        deckIndexController.chunkControllers[index.chunk].controller;

    if (chunkController is _BodyChunkEditingController) {
      final minorChunks = chunkController.chunk.minorChunks;
      final selection = chunkController
          .minorChunkControllers[index.slide].controller.selection;

      deckIndexController.removeChunkAt(index.chunk);
      deckIndexController.insertChunkAt(
          index.chunk,
          BodyChunk(
            minorChunks: minorChunks.sublist(0, index.slide).rebuild(
              (builder) {
                if (selection.baseOffset > 0) {
                  builder.add(minorChunks[index.slide]
                      .substring(0, selection.baseOffset)
                      .trim());
                }
              },
            ),
          ));
      deckIndexController.insertChunkAt(
        index.chunk + 1,
        BodyChunk(
          minorChunks: minorChunks.sublist(index.slide + 1).rebuild(
            (builder) {
              builder.insert(
                0,
                minorChunks[index.slide].substring(selection.baseOffset).trim(),
              );
            },
          ),
        ),
        focusIndex: 0,
      );
    }
    deckIndexController.notifyListeners();
  }

  void mergeWithPrevious() {
    final index = deckIndexController.index;

    final chunkController =
        deckIndexController.chunkControllers[index.chunk].controller;

    if (chunkController is _BodyChunkEditingController) {
      if (index.slide == 0) {
        if (index.chunk > 0) {
          final previousChunkController =
              deckIndexController.chunkControllers[index.chunk - 1].controller;
          if (previousChunkController is _BodyChunkEditingController) {
            final minorChunks = previousChunkController.chunk.minorChunks +
                chunkController.chunk.minorChunks;
            final focusIndex =
                previousChunkController.minorChunkControllers.length - 1;

            deckIndexController.removeChunkAt(index.chunk - 1);
            deckIndexController.removeChunkAt(index.chunk - 1);
            deckIndexController.insertChunkAt(
              index.chunk - 1,
              BodyChunk(
                minorChunks: minorChunks,
              ),
              focusIndex: focusIndex,
            );
          }
        }
      } else {
        final text =
            '${chunkController.minorChunkControllers[index.slide - 1].controller.text}\n'
            '${chunkController.minorChunkControllers[index.slide].controller.text}';

        chunkController.removeAt(index.slide - 1);
        chunkController.removeAt(index.slide - 1);
        chunkController.insertAt(index.slide - 1, text: text);
      }
    }
    deckIndexController.notifyListeners();
  }

  void mergeWithNext() {
    final index = deckIndexController.index;

    final chunkController =
        deckIndexController.chunkControllers[index.chunk].controller;

    if (chunkController is _BodyChunkEditingController) {
      if (index.slide == chunkController.minorChunkControllers.length - 1) {
        if (index.chunk < deckIndexController.chunkControllers.length - 1) {
          final nextChunkController =
              deckIndexController.chunkControllers[index.chunk + 1].controller;
          if (nextChunkController is _BodyChunkEditingController) {
            final minorChunks = chunkController.chunk.minorChunks +
                nextChunkController.chunk.minorChunks;
            final focusIndex = chunkController.minorChunkControllers.length - 1;

            deckIndexController.removeChunkAt(index.chunk);
            deckIndexController.removeChunkAt(index.chunk);
            deckIndexController.insertChunkAt(
              index.chunk,
              BodyChunk(
                minorChunks: minorChunks,
              ),
              focusIndex: focusIndex,
            );
          }
        }
      } else {
        final text =
            '${chunkController.minorChunkControllers[index.slide].controller.text}\n'
            '${chunkController.minorChunkControllers[index.slide + 1].controller.text}';

        chunkController.removeAt(index.slide);
        chunkController.removeAt(index.slide);
        chunkController.insertAt(index.slide, text: text);
      }
    }
    deckIndexController.notifyListeners();
  }
}

@immutable
class _EditingChunkBody extends StatelessWidget {
  final _DeckIndexEditingController deckIndexController;
  final _ChunkEditingController controller;

  const _EditingChunkBody({
    required this.deckIndexController,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final controller = this.controller.controller;
    if (controller is _CountdownChunkEditingController) {
      return _EditingCountdownChunkBody(
        controller: controller,
      );
    } else if (controller is _TitleChunkEditingController) {
      return _EditingTitleChunkBody(
        controller: controller,
      );
    } else if (controller is _BodyChunkEditingController) {
      return _EditingBodyChunkBody(
        deckIndexController: deckIndexController,
        controller: controller,
      );
    } else {
      return const Text('Unknown chunk type');
    }
  }
}

@immutable
class _EditingChunkSpecificButtons extends StatelessWidget {
  final _ChunkEditingController controller;

  const _EditingChunkSpecificButtons({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final controller = this.controller.controller;
    if (controller is _BodyChunkEditingController) {
      return PackedButtonRow(
        buttons: [
          PackedButton(
            debugLabel: 'Add Minor Chunk',
            child:
                const Icon(CupertinoIcons.add).padding(const EdgeInsets.all(1)),
            colour: ColourPalette.of(context).active,
            filledChildColour: ColourPalette.of(context).secondaryBackground,
            onTap: () {
              controller.insertAt(
                controller.minorChunkControllers.length,
                text: '',
              );
              controller.notifyListeners();
            },
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
  final int chunkIndex;
  final void Function() onDeleteChunk;
  final _DeckIndexEditingController deckIndexController;
  final _ChunkEditingController controller;

  const _EditingChunk({
    super.key,
    required this.chunkIndex,
    required this.onDeleteChunk,
    required this.deckIndexController,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        _ChunkTypeRadio(
          chunk: controller.chunk,
          onChangeChunk: (chunk) => controller.chunk = chunk,
        ),
        const Spacer(),
        _EditingChunkSpecificButtons(
          controller: controller,
        ),
        PackedButtonRow(
          buttons: [
            PackedButton(
              debugLabel: 'Delete Major Chunk',
              child: const Icon(CupertinoIcons.delete_solid)
                  .padding(const EdgeInsets.all(1)),
              colour: ColourPalette.of(context).danger,
              filledChildColour: ColourPalette.of(context).secondaryBackground,
              onTap: onDeleteChunk,
            ),
            PackedButton(
              debugLabel: 'Reorder Major Chunk',
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
        ).padding_(const EdgeInsets.all(4)),
      ]).background(ColourPalette.of(context).secondaryBackground),
      _EditingChunkBody(
        deckIndexController: deckIndexController,
        controller: controller,
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
  final uuid = const Uuid().v4obj();

  _DeckIndexEditingController? controller;

  late StreamSubscription<(DeckIndex?, UuidValue?)> _deckIndexSubscription;

  void updateDeckIndex((DeckIndex?, UuidValue?) event) {
    final (deckIndex, source) = event;
    print("Update coming in, refresh is ${source != uuid}");

    if (source != uuid) {
      setState(() {
        if (deckIndex == null) {
          controller?.dispose();
          controller = null;
        } else {
          if (controller == null) {
            controller = _DeckIndexEditingController(deckIndex)
              ..addListener(() {
                print('got notified');
                widget.deckIndex.publish((controller?.deckIndex, uuid));
                setState(() {});
              });
          } else {
            controller!.deckIndex = deckIndex;
          }
        }
      });
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
      controller?.dispose();
      controller = null;
      _deckIndexSubscription = widget.deckIndex.subscribe(updateDeckIndex);
    }
  }

  @override
  void dispose() {
    _deckIndexSubscription.cancel();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) {
      return Container();
    } else {
      return FocusTraversalGroup(
        child: Column(children: [
          Row(children: [
            _CommentField(controller: controller).expanded(),
            PackedButtonRow(
              buttons: [
                PackedButton(
                  debugLabel: 'Add Major Chunk',
                  child: const Icon(CupertinoIcons.add)
                      .padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).active,
                  filledChildColour:
                      ColourPalette.of(context).secondaryBackground,
                  onTap: () => setState(() => controller.insertChunkAt(
                        controller.index.chunk + 1,
                        BodyChunk(minorChunks: [''].toBuiltList()),
                      )),
                )
              ].toBuiltList(),
            ),
          ]).padding(const EdgeInsets.all(16)),
          ReorderableList(
            itemBuilder: (context, index) {
              return _EditingChunk(
                key: ValueKey(index),
                chunkIndex: index,
                onDeleteChunk: () {
                  setState(() {
                    controller.chunkControllers.removeAt(index).dispose();
                  });
                },
                deckIndexController: controller,
                controller: controller.chunkControllers[index],
              );
            },
            itemCount: controller.chunkControllers.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  // removing the item at oldIndex will shorten the list by 1.
                  newIndex -= 1;
                }
                final chunkController =
                    controller.chunkControllers.removeAt(oldIndex);
                controller.chunkControllers.insert(newIndex, chunkController);
              });
            },
          ).expanded(),
        ]).background(ColourPalette.of(context).secondaryBackground),
      );
    }
  }
}
