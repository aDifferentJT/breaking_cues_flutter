import 'package:built_collection/built_collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:core/deck.dart';
import 'package:core/message.dart';
import 'package:flutter_utils/widget_modifiers.dart';
import 'package:output/output.dart';

import 'animation_trigger.dart';
import 'settings_controls.dart';

enum _Tab {
  outputs,
  settings;

  @override
  String toString() {
    switch (this) {
      case _Tab.outputs:
        return "Outputs";
      case _Tab.settings:
        return "Settings";
    }
  }
}

class DockedPreview extends StatefulWidget {
  final Stream<Message> stream;
  final BuiltMap<String, DisplaySettings> defaultSettings;
  final Deck? deck;
  final void Function(Deck)? updateDeck;

  const DockedPreview({
    super.key,
    required this.stream,
    required this.defaultSettings,
    this.deck,
    this.updateDeck,
  });

  @override
  createState() => _DockedPreviewState();
}

class _DockedPreviewState extends State<DockedPreview>
    with SingleTickerProviderStateMixin {
  late String _name;

  late final AnimationController _animation;

  var _tab = _Tab.outputs;

  void _getName() {
    _name = widget.defaultSettings.isNotEmpty
        ? widget.defaultSettings.keys.first
        : "";
  }

  @override
  void initState() {
    super.initState();

    _getName();

    _animation = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )
      ..addListener(() => setState(() {}))
      ..value = 1;
  }

  @override
  void didUpdateWidget(covariant DockedPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.defaultSettings.containsKey(_name)) {
      _getName();
    }
  }

  OptionalDisplaySettings get displaySettings =>
      widget.deck?.displaySettings[_name] ?? const OptionalDisplaySettings();

  DisplaySettings get defaultSettings =>
      widget.defaultSettings[_name] ?? const DisplaySettings.default_();

  void updateDisplaySettings(
    OptionalDisplaySettings newDisplaySettings,
  ) {
    if (widget.updateDeck != null) {
      widget.updateDeck!(
        widget.deck!.withDisplaySettings(
          widget.deck!.displaySettings.rebuild(
            (builder) => builder[_name] = newDisplaySettings,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final openHeight = constraints.maxHeight;
      const closeHeight = 30.0;
      final height = TweenSequence([
        TweenSequenceItem(
          tween: ConstantTween(0.0),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: 0.0,
            end: openHeight,
          ),
          weight: 1,
        ),
      ]).evaluate(_animation);

      const controlWidth = 40.0;
      final controlBarWidth = TweenSequence([
        TweenSequenceItem(
          tween: Tween(
            begin: constraints.maxWidth,
            end: controlWidth,
          ),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: ConstantTween(controlWidth),
          weight: 1,
        ),
      ]).evaluate(_animation);

      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          Row(
            children: [
              ListView(
                children: [
                  _Tab.outputs,
                  ...?(widget.deck != null ? [_Tab.settings] : null),
                ].map((tab) {
                  return Text("$tab")
                      .rotated(quarterTurns: 1)
                      .container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _tab == tab
                              ? CupertinoColors.darkBackgroundGray
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(4),
                          ),
                        ),
                      )
                      .gestureDetector(
                        onTap: () => setState(() => _tab = tab),
                      );
                }).toList(growable: false),
              )
                  .container(
                    padding: const EdgeInsets.only(left: 4),
                    color: Colors.black,
                  )
                  .sized(width: 30),
              () {
                switch (_tab) {
                  case _Tab.outputs:
                    return ListView.separated(
                      itemBuilder: (context, index) {
                        return Row(children: [
                          Text(widget.defaultSettings.keys.elementAt(index))
                              .padding(const EdgeInsets.all(5)),
                          const Spacer(),
                          const Icon(CupertinoIcons.right_chevron),
                        ])
                            .background(_name ==
                                    widget.defaultSettings.keys.elementAt(index)
                                ? CupertinoColors.activeBlue
                                : Colors.transparent)
                            .gestureDetector(onTap: () {
                          setState(() {
                            _name =
                                widget.defaultSettings.keys.elementAt(index);
                          });
                        });
                      },
                      separatorBuilder: (context, _) =>
                          const Divider(height: 0),
                      itemCount: widget.defaultSettings.length,
                    );
                  case _Tab.settings:
                    return ListView(children: [
                      OptionalDisplaySettingsControl(
                        displaySettings: displaySettings,
                        update: updateDisplaySettings,
                        defaultSettings: defaultSettings,
                      ),
                    ]);
                }
              }()
                  .expanded(),
              Stack(children: [
                Container(color: Colors.blueGrey).positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  bottom: 0,
                ),
                ScaledOutput(stream: widget.stream, name: _name)
                    .aspectRatio(16 / 9),
              ]).centered().expanded(),
            ],
          )
              .sized(height: openHeight)
              .overflow(
                alignment: Alignment.topCenter,
                maxHeight: openHeight,
              )
              .sized(height: height)
              .clipped(),
          Row(children: [
            const Text("Preview").centered().expanded(),
            AnimatedIcon(icon: AnimatedIcons.menu_close, progress: _animation)
                .centered()
                .sized(width: controlWidth)
          ])
              .background(Colors.grey)
              .gestureDetector(onTap: () => _animation.trigger())
              .sized(width: controlBarWidth, height: closeHeight),
        ],
      ).background(CupertinoColors.darkBackgroundGray);
    });
  }
}
