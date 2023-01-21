import 'dart:async';

import 'package:built_collection/built_collection.dart';
import 'package:client/packed_button_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/deck.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'settings_controls.dart';

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
            PackedButtonRow(
              buttons: [
                PackedButton(
                  child: const Icon(CupertinoIcons.add)
                      .padding(const EdgeInsets.all(4)),
                  colour: CupertinoColors.activeBlue,
                  onTap: () => widget.updateStreamSink.add(programme), // TODO
                )
              ].toBuiltList(),
              padding: const EdgeInsets.all(1),
            ),
          ],
        ).container(
          padding: const EdgeInsets.all(20),
          color: CupertinoColors.darkBackgroundGray,
        ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: DisplaySettingsPanel(
              displaySettings: programme.defaultSettings,
              update: (settings) => widget.updateStreamSink
                  .add(programme.withDefaultSettings(settings)),
            ),
          ),
        ),
      ],
    );
  }
}
