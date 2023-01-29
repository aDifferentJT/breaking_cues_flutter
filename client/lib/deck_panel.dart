import 'package:collection/collection.dart';

import 'package:flutter/material.dart';

import 'package:core/deck.dart';
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
                        Text(slide.label)
                            .container(
                              padding: const EdgeInsets.all(8),
                              color:
                                  Index(chunk: chunkIndex, slide: slideIndex) ==
                                          deckIndex.index
                                      ? ColourPalette.of(context).active
                                      : ColourPalette.of(context).background,
                            )
                            .gestureDetector(onTap: () => select(index)),
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
