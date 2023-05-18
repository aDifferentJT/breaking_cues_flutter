import 'package:built_collection/built_collection.dart';
import 'package:client/packed_button_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'colours.dart';
import 'form.dart';

@immutable
class ClientSettingsPanel extends StatelessWidget {
  final String serverAddress;
  final void Function(String) setServerAddress;
  final bool connected;
  final void Function() connect;
  final void Function() disconnect;

  final void Function(ColourPalette) setColourPalette;

  const ClientSettingsPanel({
    super.key,
    required this.serverAddress,
    required this.setServerAddress,
    required this.connected,
    required this.connect,
    required this.disconnect,
    required this.setColourPalette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Settings", style: ColourPalette.of(context).headingStyle)
            .container(
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.all(20),
          color: ColourPalette.of(context).secondaryBackground,
        ),
        ListView(children: [
          Column(children: [
            BCForm<String>(
              value: serverAddress,
              onChange: setServerAddress,
              backgroundColour: ColourPalette.of(context).background,
              fields: [
                BCTextFormField(
                  label: const Text('Server Address:'),
                  getter: (serverAddress) => serverAddress,
                  setter: (_) => (newServerAddress) => newServerAddress,
                  maxLines: 1,
                )
              ],
            ),
            PackedButtonRow(
              buttons: [
                PackedButton(
                  child: const Text('Connect').padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).foreground,
                  filledChildColour: ColourPalette.of(context).background,
                  onTap: connect,
                ),
                PackedButton(
                  child:
                      const Text('Disconnect').padding(const EdgeInsets.all(4)),
                  colour: ColourPalette.of(context).foreground,
                  filledChildColour: ColourPalette.of(context).background,
                  onTap: disconnect,
                ),
              ].toBuiltList(),
            ).padding_(const EdgeInsets.all(4)),
          ]).background(
            connected
                ? ColourPalette.of(context).success
                : ColourPalette.of(context).danger,
          ),
          Divider(
            thickness: 1.5,
            color: ColourPalette.of(context).secondaryBackground,
          ),
          BCForm<ColourPalette>(
            value: ColourPalette.of(context),
            onChange: setColourPalette,
            backgroundColour: ColourPalette.of(context).background,
            fields: [
              BCRadioFormField<ColourPalette, ColourPalette>(
                label: const Text('Client Theme:')
                    .padding(const EdgeInsets.all(4)),
                getter: (colourPalette) => colourPalette,
                setter: (_) => (newColourPalette) => newColourPalette,
                options: [
                  BCRadioOption(
                    value: const ColourPalette.dark(),
                    child: const Text('Dark').padding(const EdgeInsets.all(4)),
                    colour: ColourPalette.of(context).foreground,
                  ),
                  BCRadioOption(
                    value: const ColourPalette.light(),
                    child: const Text('Light').padding(const EdgeInsets.all(4)),
                    colour: ColourPalette.of(context).foreground,
                  ),
                ].toBuiltList(),
              ),
            ],
          ).padding(const EdgeInsets.symmetric(vertical: 8)),
        ]).background(ColourPalette.of(context).background).expanded(),
      ],
    );
  }
}
