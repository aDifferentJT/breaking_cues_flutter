import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:client/settings_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'button.dart';
import 'open_save.dart';

class _SettingsRow extends StatefulWidget {
  final String name;
  final DisplaySettings settings;
  final void Function(DisplaySettings) update;
  final bool selected;
  final void Function() select;

  const _SettingsRow({
    required this.name,
    required this.settings,
    required this.update,
    required this.selected,
    required this.select,
  });

  @override
  State<StatefulWidget> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController openAnimation;

  @override
  void initState() {
    super.initState();

    openAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() => setState(() {}));

    if (widget.selected) {
      openAnimation.forward();
    } else {
      openAnimation.reverse();
    }
  }

  @override
  void didUpdateWidget(covariant _SettingsRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selected) {
      openAnimation.forward();
    } else {
      openAnimation.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        Text(widget.name),
        const Spacer(),
        const Icon(CupertinoIcons.chevron_right).transform(
            transform: Matrix4.rotationZ(
              Tween(begin: 0.0, end: pi / 2).evaluate(openAnimation),
            ),
            alignment: Alignment.center),
      ])
          .container(
            padding: const EdgeInsets.all(8),
            color: widget.selected
                ? CupertinoColors.activeBlue
                : Colors.transparent,
          )
          .gestureDetector(onTap: widget.select),
      DisplaySettingsControl(
        displaySettings: widget.settings,
        update: widget.update,
      )
          .container(color: CupertinoColors.darkBackgroundGray)
          .padding(const EdgeInsets.only(left: 16, bottom: 8))
          .sizeTransition(
            sizeFactor: openAnimation,
          ),
    ]);
  }
}

class GlobalSettingsPanel extends StatefulWidget {
  final Stream<Programme> updateStream;
  final StreamSink<Programme> updateStreamSink;

  const GlobalSettingsPanel({
    super.key,
    required this.updateStream,
    required this.updateStreamSink,
  });

  @override
  createState() => _GlobalSettingsPanelState();
}

class _GlobalSettingsPanelState extends State<GlobalSettingsPanel> {
  var programme = Programme.new_();
  var selected = '';

  late final StreamSubscription<Programme> _updateStreamSubscription;

  void processUpdate(Programme newProgramme) =>
      setState(() => programme = newProgramme);

  @override
  void initState() {
    super.initState();

    _updateStreamSubscription = widget.updateStream.listen(processUpdate);
  }

  @override
  void didUpdateWidget(covariant GlobalSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.updateStream != oldWidget.updateStream) {
      _updateStreamSubscription.cancel();
      _updateStreamSubscription = widget.updateStream.listen(processUpdate);
    }
  }

  @override
  dispose() {
    _updateStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              "Settings",
              style: Theme.of(context).primaryTextTheme.headlineSmall,
            ),
            const Spacer(),
            OpenButton(onOpen: widget.updateStreamSink.add)
                .padding(const EdgeInsets.symmetric(horizontal: 4)),
            SaveButton(programme: programme)
                .padding(const EdgeInsets.symmetric(horizontal: 4)),
            const SizedBox(width: 32),
            Button(
              onTap: () => widget.updateStreamSink.add(
                programme, // TODO
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: CupertinoColors.activeBlue,
              ),
            ).padding(const EdgeInsets.symmetric(horizontal: 4)),
          ],
        ).container(
          padding: const EdgeInsets.all(20),
          color: CupertinoColors.darkBackgroundGray,
        ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: ListView(
              children: programme.defaultSettings.entries.map((entry) {
                return _SettingsRow(
                  name: entry.key,
                  settings: entry.value,
                  update: (newSettings) => widget.updateStreamSink.add(programme
                      .withDefaultSettings(programme.defaultSettings.rebuild(
                          (builder) => builder[entry.key] = newSettings))),
                  selected: selected == entry.key,
                  select: () => setState(() => selected = entry.key),
                );
              }).toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }
}
