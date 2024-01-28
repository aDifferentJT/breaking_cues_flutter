import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:core/pubsub.dart';
import 'package:flutter/material.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'colours.dart';
import 'deck_panel.dart';
import 'docked_preview.dart';

class LivePanel extends StatefulWidget {
  final PubSub<Message> pubSub;

  const LivePanel({
    super.key,
    required this.pubSub,
  });

  @override
  LivePanelState createState() => LivePanelState();
}

class LivePanelState extends State<LivePanel> {
  var defaultSettings = BuiltMap<String, DisplaySettings>();
  DeckIndex? deckIndex;

  late StreamSubscription<Message> _streamSubscription;

  void process(Message message) {
    if (message is ShowMessage) {
      setState(() {
        defaultSettings = message.defaultSettings;
        deckIndex = message.deckIndex;
      });
    } else if (message is CloseMessage) {
      setState(() => deckIndex = null);
    } else {
      throw ArgumentError.value(message, "Message type not recognised");
    }
  }

  void select(Index index) {
    if (deckIndex != null) {
      widget.pubSub.publish(ShowMessage(
        defaultSettings: defaultSettings,
        quiet: true,
        deckIndex: DeckIndex(
          deck: deckIndex!.deck,
          index: index,
        ),
      ));
    }
  }

  @override
  void initState() {
    super.initState();

    _streamSubscription = widget.pubSub.subscribe(process);
  }

  @override
  void didUpdateWidget(covariant LivePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pubSub != oldWidget.pubSub) {
      _streamSubscription.cancel();
      _streamSubscription = widget.pubSub.subscribe(process);
    }
  }

  @override
  dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          LayoutBuilder(builder: (context, constraints) {
            return Column(children: [
              (deckIndex == null
                      ? const Text("Nothing Live")
                          .centered()
                          .background(ColourPalette.of(context).background)
                      : DeckPanel(
                          deckIndex: deckIndex!,
                          select: select,
                        ))
                  .expanded(),
              DockedPreview(
                pubSub: widget.pubSub,
                defaultSettings: defaultSettings,
              ).constrained(constraints),
            ]);
          }).expanded(),
          Icon(Icons.close, color: ColourPalette.of(context).background)
              .centered()
              .container(
                color: ColourPalette.of(context).danger,
                width: 40,
              )
              .gestureDetector(
                onTap: () => widget.pubSub.publish(CloseMessage()),
              ),
        ]).expanded(),
      ],
    );
  }
}
