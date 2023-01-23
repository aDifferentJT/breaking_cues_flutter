import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
import 'package:flutter_utils/widget_modifiers.dart';
import 'package:output/output.dart';

import 'colours.dart';
import 'left_tabs.dart';

class DockedPreview extends StatefulWidget {
  final StreamSink<void> requestUpdateStreamSink;
  final Stream<Message> stream;
  final BuiltMap<String, DisplaySettings> defaultSettings;
  final Deck? deck;
  final void Function(Deck)? updateDeck;

  const DockedPreview({
    super.key,
    required this.requestUpdateStreamSink,
    required this.stream,
    required this.defaultSettings,
    this.deck,
    this.updateDeck,
  });

  @override
  createState() => _DockedPreviewState();
}

class _DockedPreviewState extends State<DockedPreview> {
  static const handleHeight = 10.0;

  var height = 0.0;

  void adjustHeight(double delta, {required BoxConstraints constraints}) {
    setState(
      () {
        height = (height - delta).clamp(0, constraints.maxHeight);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(children: [
        Container(
          decoration: ShapeDecoration(
            color: ColourPalette.of(context).secondaryForeground,
            shape: const StadiumBorder(),
          ),
          width: handleHeight * 3,
          height: handleHeight / 2,
        )
            .container(
              alignment: Alignment.center,
              color: ColourPalette.of(context).background,
              height: handleHeight,
            )
            .gestureDetector(
              onTap: () => setState(() {
                if (height == 0) {
                  height = constraints.maxHeight / 3;
                } else {
                  height = 0;
                }
              }),
              onDoubleTap: () => setState(() {
                height = constraints.maxHeight / 3;
              }),
              onVerticalDragUpdate: (details) => adjustHeight(
                details.primaryDelta ?? 0,
                constraints: constraints,
              ),
            ),
        LeftTabs(
          keepHiddenChildrenAlive: true,
          children: widget.defaultSettings.keys
              .map((name) => TabEntry(
                    icon: Text(name).rotated(quarterTurns: 1),
                    body: Stack(children: [
                      Container(color: Colors.blueGrey).positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        bottom: 0,
                      ),
                      ScaledOutput(
                        requestUpdateStreamSink: widget.requestUpdateStreamSink,
                        stream: widget.stream,
                        name: name,
                      ).aspectRatio(16 / 9),
                    ]).centered(),
                  ))
              .toList(growable: false),
        ).expanded(),
      ]).background(ColourPalette.of(context).secondaryBackground).constrained(
            BoxConstraints(
              maxHeight: height + handleHeight,
            ),
          );
    });
  }
}
