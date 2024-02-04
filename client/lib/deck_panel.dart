import 'package:collection/collection.dart';
import 'package:core/pubsub.dart';
import 'package:core/streams.dart';

import 'package:flutter/material.dart';

import 'package:core/deck.dart';
import 'package:flutter/services.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'colours.dart';

class DeckPanel extends StatelessWidget {
  final DeckIndex deckIndex;
  final void Function(Index) select;

  const DeckPanel({
    super.key,
    required this.deckIndex,
    required this.select,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        deckIndex.deck.label,
        style: ColourPalette.of(context).headingStyle,
      ).container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
      ),
      ListView(
        children: deckIndex.deck.chunks
            .expandIndexed((chunkIndex, chunk) => [
                  ...chunk.slides.expandIndexed(
                    (slideIndex, slide) {
                      final index = Index(chunk: chunkIndex, slide: slideIndex);
                      return [
                        Builder(
                          builder: (context) => Text(slide.label).container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  Index(chunk: chunkIndex, slide: slideIndex) ==
                                          deckIndex.index
                                      ? ColourPalette.of(context).active
                                      : ColourPalette.of(context).background,
                              boxShadow: Focus.of(context).hasPrimaryFocus
                                  ? [ColourPalette.of(context).focusedShadow()]
                                  : null,
                            ),
                          ),
                        )
                            .focus()
                            .gestureDetector(onTap: () => select(index))
                            .callbackShortcuts(bindings: {
                          const SingleActivator(LogicalKeyboardKey.space): () =>
                              select(index),
                        }),
                        Divider(
                          color: ColourPalette.of(context).secondaryBackground,
                          height: 0,
                          thickness: 1,
                        ),
                      ];
                    },
                  ),
                  Divider(
                    color: ColourPalette.of(context).secondaryBackground,
                    height: 8,
                    thickness: 8,
                  ),
                ])
            .toList(growable: false),
      ).expanded(),
    ]).background(ColourPalette.of(context).secondaryBackground);
  }
}

class PreviewDeckPanelPubSub extends StatefulWidget {
  final PubSub<Update> update;
  final PubSub<DeckKeyIndex?> preview;

  final void Function(Index) select;

  const PreviewDeckPanelPubSub({
    super.key,
    required this.update,
    required this.preview,
    required this.select,
  });

  @override
  createState() => PreviewDeckPanelPubSubState();
}

class PreviewDeckPanelPubSubState extends State<PreviewDeckPanelPubSub> {
  late final CachedPubSub<Update> cachedUpdate;
  late final CachedPubSub<DeckKeyIndex?> cachedPreview;

  DeckIndex? get deckIndex => cachedPreview.value == null
      ? null
      : cachedUpdate.value?.programme.deckIndexForKey(cachedPreview.value!);

  @override
  void initState() {
    super.initState();
    cachedUpdate =
        widget.update.borrowed.cached(onUpdate: (_) => setState(() => ()));
    cachedPreview =
        widget.preview.borrowed.cached(onUpdate: (_) => setState(() => ()));
  }

  @override
  void didUpdateWidget(covariant PreviewDeckPanelPubSub oldWidget) {
    if (widget.update != oldWidget.update) {
      cachedUpdate.dispose();
      cachedUpdate =
          widget.update.borrowed.cached(onUpdate: (_) => setState(() => ()));
    }
    if (widget.preview != oldWidget.preview) {
      cachedPreview.dispose();
      cachedPreview =
          widget.preview.borrowed.cached(onUpdate: (_) => setState(() => ()));
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    cachedUpdate.dispose();
    cachedPreview.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => deckIndex == null
      ? const CircularProgressIndicator()
      : DeckPanel(deckIndex: deckIndex!, select: widget.select);
}
