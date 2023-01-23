import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'colours.dart';
import 'form.dart';

@immutable
class ClientSettingsPanel extends StatelessWidget {
  final void Function(ColourPalette) setColourPalette;

  const ClientSettingsPanel({super.key, required this.setColourPalette});

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
