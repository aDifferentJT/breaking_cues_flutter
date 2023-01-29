import 'package:built_collection/built_collection.dart';
import 'package:core/deck.dart';
import 'package:core/bible_fetcher.dart';
import 'package:core/hymn_fetcher.dart';
import 'package:core/psalm_fetcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'colours.dart';
import 'form.dart';
import 'left_tabs.dart';

@immutable
class _FetchButtonContent extends StatelessWidget {
  final Future<Deck?>? deck;

  const _FetchButtonContent({required this.deck});

  @override
  Widget build(BuildContext context) {
    if (deck == null) {
      return Text('Fetch', style: ColourPalette.of(context).headingStyle);
    } else {
      return FutureBuilder(
          future: deck,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return const Text('Error');
              case ConnectionState.active:
              case ConnectionState.waiting:
                return const CupertinoActivityIndicator();
              case ConnectionState.done:
                if (snapshot.hasData) {
                  return const Text('Done');
                } else {
                  return const Text('Error');
                }
            }
          });
    }
  }
}

@immutable
class _FetchButton extends StatefulWidget {
  final Future<Deck?> Function() fetch;
  final void Function(Deck) updateDeck;

  const _FetchButton(this.fetch, {required this.updateDeck});

  @override
  createState() => _FetchButtonState();
}

class _FetchButtonState extends State<_FetchButton> {
  Future<Deck?>? deck;

  @override
  Widget build(BuildContext context) {
    return _FetchButtonContent(deck: deck)
        .container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColourPalette.of(context).active,
              borderRadius: const BorderRadius.all(Radius.circular(8)),
            ))
        .gestureDetector(
          onTap: () => setState(() {
            deck = widget.fetch();
            deck!.then((deck) {
              if (deck != null) {
                widget.updateDeck(deck);
              }
            });
          }),
        )
        .padding(const EdgeInsets.all(8));
  }
}

@immutable
class _BibleFetchPanel extends StatefulWidget {
  final DeckKey deckKey;
  final void Function(Deck) updateDeck;

  const _BibleFetchPanel({
    required this.deckKey,
    required this.updateDeck,
  });

  @override
  createState() => _BibleFetchPanelState();
}

class _BibleFetchPanelState extends State<_BibleFetchPanel> {
  var bibleParams = const BibleParams();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        children: [
          Text("Fetch Bible", style: ColourPalette.of(context).headingStyle),
          const Spacer(),
        ],
      ).container(
        padding: const EdgeInsets.all(20),
        color: ColourPalette.of(context).secondaryBackground,
      ),
      ListView(children: [
        BCForm<BibleParams>(
          value: bibleParams,
          onChange: (newParams) => setState(() => bibleParams = newParams),
          backgroundColour: ColourPalette.of(context).background,
          fields: [
            BCTextFormField(
              label: const Text('Query:'),
              getter: (hymnParams) => hymnParams.query,
              setter: (hymnParams) => hymnParams.withQuery,
            ),
            BCTextFormField(
              label: const Text('Version:'),
              getter: (hymnParams) => hymnParams.version,
              setter: (hymnParams) => hymnParams.withVersion,
            ),
          ],
        ),
      ]).expanded(),
      _FetchButton(
        () => fetchBible(bibleParams, deckKey: widget.deckKey),
        updateDeck: widget.updateDeck,
      ),
    ]).background(ColourPalette.of(context).background);
  }
}

@immutable
class _PsalmFetchPanel extends StatefulWidget {
  final DeckKey deckKey;
  final void Function(Deck) updateDeck;

  const _PsalmFetchPanel({
    required this.deckKey,
    required this.updateDeck,
  });

  @override
  createState() => _PsalmFetchPanelState();
}

class _PsalmFetchPanelState extends State<_PsalmFetchPanel> {
  var psalmParams = const PsalmParams();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        children: [
          Text("Fetch Psalm", style: ColourPalette.of(context).headingStyle),
          const Spacer(),
        ],
      ).container(
        padding: const EdgeInsets.all(20),
        color: ColourPalette.of(context).secondaryBackground,
      ),
      ListView(children: [
        BCForm<PsalmParams>(
          value: psalmParams,
          onChange: (newParams) => setState(() => psalmParams = newParams),
          backgroundColour: ColourPalette.of(context).background,
          fields: [
            BCRadioFormField(
              label: const Text('Psalter:').padding(const EdgeInsets.all(4)),
              getter: (psalmParams) => psalmParams.psalter,
              setter: (psalmParams) => psalmParams.withPsalter,
              options: [
                BCRadioOption(
                  value: Psalter.bcp,
                  child: const Text('BCP').padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).active,
                ),
                BCRadioOption(
                  value: Psalter.cw,
                  child: const Text('CW').padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).active,
                ),
              ].toBuiltList(),
            ),
            BCIntFormField(
              label: const Text('Number:').padding(const EdgeInsets.all(4)),
              getter: (psalmParams) => psalmParams.number,
              setter: (psalmParams) => psalmParams.withNumber,
            ),
            BCIntFormField(
              label:
                  const Text('Start verse:').padding(const EdgeInsets.all(4)),
              getter: (psalmParams) => psalmParams.startVerse,
              setter: (psalmParams) => psalmParams.withStartVerse,
            ),
            BCIntFormField(
              label: const Text('End verse:').padding(const EdgeInsets.all(4)),
              getter: (psalmParams) => psalmParams.endVerse,
              setter: (psalmParams) => psalmParams.withEndVerse,
            ),
            BCTickBoxFormField(
              label: const Text('Gloria:').padding(const EdgeInsets.all(4)),
              getter: (psalmParams) => psalmParams.gloria,
              setter: (psalmParams) => psalmParams.withGloria,
            ),
            BCIntFormField(
              label: const Text(
                'Verses per\nMinor Chunk:',
                textAlign: TextAlign.right,
              ).padding(const EdgeInsets.all(4)),
              getter: (psalmParams) => psalmParams.versesPerMinorChunk,
              setter: (psalmParams) => psalmParams.withVersesPerMinorChunk,
            ),
            BCIntFormField(
              label: const Text(
                'Minor Chunks per\nMajor Chunk:',
                textAlign: TextAlign.right,
              ).padding(const EdgeInsets.all(4)),
              getter: (psalmParams) => psalmParams.minorChunksPerMajorChunk,
              setter: (psalmParams) => psalmParams.withMinorChunksPerMajorChunk,
            ),
            BCRadioFormField(
              label: const Text('Bold:').padding(const EdgeInsets.all(4)),
              getter: (psalmParams) => psalmParams.bold,
              setter: (psalmParams) => psalmParams.withBold,
              options: [
                BCRadioOption(
                  value: PsalmBold.none,
                  child: const Text('None').padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).active,
                ),
                BCRadioOption(
                  value: PsalmBold.oddVerses,
                  child: const Text('Odd').padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).active,
                ),
                BCRadioOption(
                  value: PsalmBold.secondHalf,
                  child:
                      const Text('2nd Half').padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).active,
                ),
              ].toBuiltList(),
            ),
          ],
        ),
      ]).expanded(),
      _FetchButton(
        () => fetchPsalm(psalmParams, deckKey: widget.deckKey),
        updateDeck: widget.updateDeck,
      ),
    ]).background(ColourPalette.of(context).background);
  }
}

@immutable
class _HymnFetchPanel extends StatefulWidget {
  final DeckKey deckKey;
  final void Function(Deck) updateDeck;

  const _HymnFetchPanel({
    required this.deckKey,
    required this.updateDeck,
  });

  @override
  createState() => _HymnFetchPanelState();
}

class _HymnFetchPanelState extends State<_HymnFetchPanel> {
  var hymnParams = const HymnParams();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
        children: [
          Text("Fetch Hymn", style: ColourPalette.of(context).headingStyle),
          const Spacer(),
        ],
      ).container(
        padding: const EdgeInsets.all(20),
        color: ColourPalette.of(context).secondaryBackground,
      ),
      ListView(children: [
        BCForm<HymnParams>(
          value: hymnParams,
          onChange: (newParams) => setState(() => hymnParams = newParams),
          backgroundColour: ColourPalette.of(context).background,
          fields: [
            BCRadioFormField(
              label: const Text('Hymnal:'),
              getter: (hymnParams) => hymnParams.hymnal,
              setter: (hymnParams) => hymnParams.withHymnal,
              options: [
                BCRadioOption(
                  value: Hymnal.neh,
                  child: const Text('NEH').padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).active,
                ),
              ].toBuiltList(),
            ),
            BCIntFormField(
              label: const Text('Number:'),
              getter: (hymnParams) => hymnParams.number,
              setter: (hymnParams) => hymnParams.withNumber,
            ),
            BCIntFormField(
              label: const Text('Lines per Minor Chunk:'),
              getter: (hymnParams) => hymnParams.linesPerMinorChunk,
              setter: (hymnParams) => hymnParams.withLinesPerMinorChunk,
            ),
          ],
        ),
      ]).expanded(),
      _FetchButton(
        () => fetchHymn(hymnParams, deckKey: widget.deckKey),
        updateDeck: widget.updateDeck,
      ),
    ]).background(ColourPalette.of(context).background);
  }
}

@immutable
class FetchPanel extends StatelessWidget {
  final DeckKey deckKey;
  final void Function(Deck) updateDeck;

  const FetchPanel({
    super.key,
    required this.deckKey,
    required this.updateDeck,
  });

  @override
  Widget build(BuildContext context) {
    return LeftTabs(keepHiddenChildrenAlive: true, children: [
      TabEntry(
        icon: const Text("Bible").rotated(quarterTurns: 1),
        body: _BibleFetchPanel(deckKey: deckKey, updateDeck: updateDeck),
      ),
      TabEntry(
        icon: const Text("Psalm").rotated(quarterTurns: 1),
        body: _PsalmFetchPanel(deckKey: deckKey, updateDeck: updateDeck),
      ),
      TabEntry(
        icon: const Text("Hymn").rotated(quarterTurns: 1),
        body: _HymnFetchPanel(deckKey: deckKey, updateDeck: updateDeck),
      ),
    ]);
  }
}
