import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'deck_panel.dart';
import 'docked_preview.dart';

class LivePanel extends StatefulWidget {
  final StreamSink<void> requestUpdateStreamSink;
  final Stream<Message> stream;
  final StreamSink<Message> streamSink;

  const LivePanel({
    super.key,
    required this.requestUpdateStreamSink,
    required this.stream,
    required this.streamSink,
  });

  @override
  LivePanelState createState() => LivePanelState();
}

class LivePanelState extends State<LivePanel> {
  var defaultSettings = BuiltMap<String, DisplaySettings>();
  DeckIndex? deckIndex;

  late final StreamSubscription<Message> _streamSubscription;

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
      widget.streamSink.add(ShowMessage(
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

    _streamSubscription = widget.stream.listen(process);
  }

  @override
  void didUpdateWidget(covariant LivePanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.stream != oldWidget.stream) {
      _streamSubscription.cancel();
      _streamSubscription = widget.stream.listen(process);
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
                          .background(Colors.black)
                      : DeckPanel(
                          deckIndex: deckIndex!,
                          select: select,
                        ))
                  .expanded(),
              DockedPreview(
                requestUpdateStreamSink: widget.requestUpdateStreamSink,
                stream: widget.stream,
                defaultSettings: defaultSettings,
              ).constrained(constraints),
            ]);
          }).expanded(),
          const Icon(Icons.close, color: Colors.black)
              .centered()
              .container(
                color: const Color.fromARGB(255, 255, 0, 0),
                width: 40,
              )
              .gestureDetector(
                onTap: () => widget.streamSink.add(CloseMessage()),
              ),
        ]).expanded(),
      ],
    );
  }
}
