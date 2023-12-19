import 'dart:io';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:client/form.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:core/deck.dart';
import 'package:flutter/services.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'colours.dart';

@immutable
class StyleControl extends StatelessWidget {
  final Style style;
  final Style? selected;
  final void Function(Style) setStyle;

  const StyleControl({
    super.key,
    required this.style,
    required this.selected,
    required this.setStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colour = style == selected
        ? ColourPalette.of(context).active
        : ColourPalette.of(context).foreground;
    return () {
      switch (style) {
        case Style.none:
          return Container();
        case Style.topLines:
          return Column(children: [
            Container(color: colour).expanded(flex: 1),
            Container(color: Colors.transparent).expanded(flex: 2),
          ]).padding(const EdgeInsets.all(1));
        case Style.leftQuarter:
          return Row(children: [
            Container(color: colour).expanded(flex: 1),
            Container(color: Colors.transparent).expanded(flex: 3),
          ]);
        case Style.leftThird:
          return Row(children: [
            Container(color: colour).expanded(flex: 1),
            Container(color: Colors.transparent).expanded(flex: 2),
          ]).padding(const EdgeInsets.all(1));
        case Style.leftHalf:
          return Row(children: [
            Container(color: colour).expanded(flex: 1),
            Container(color: Colors.transparent).expanded(flex: 1),
          ]).padding(const EdgeInsets.all(1));
        case Style.leftTwoThirds:
          return Row(children: [
            Container(color: colour).expanded(flex: 2),
            Container(color: Colors.transparent).expanded(flex: 1),
          ]);
        case Style.fullScreen:
          return Container(color: colour);
        case Style.rightTwoThirds:
          return Row(children: [
            Container(color: Colors.transparent).expanded(flex: 1),
            Container(color: colour).expanded(flex: 2),
          ]);
        case Style.rightHalf:
          return Row(children: [
            Container(color: Colors.transparent).expanded(flex: 1),
            Container(color: colour).expanded(flex: 1),
          ]).padding(const EdgeInsets.all(1));
        case Style.rightThird:
          return Row(children: [
            Container(color: Colors.transparent).expanded(flex: 2),
            Container(color: colour).expanded(flex: 1),
          ]).padding(const EdgeInsets.all(1));
        case Style.rightQuarter:
          return Row(children: [
            Container(color: Colors.transparent).expanded(flex: 3),
            Container(color: colour).expanded(flex: 1),
          ]);
        case Style.bottomLines:
          return Column(children: [
            Container(color: Colors.transparent).expanded(flex: 2),
            Container(color: colour).expanded(flex: 1),
          ]).padding(const EdgeInsets.all(1));
        case Style.bottomParagraphs:
          return Column(children: [
            Container(color: Colors.transparent).expanded(flex: 1),
            Row(children: [
              Container(color: colour)
                  .padding_(const EdgeInsets.all(1))
                  .expanded(flex: 1),
              Container(color: colour)
                  .padding_(const EdgeInsets.all(1))
                  .expanded(flex: 1),
            ]).expanded(flex: 1),
          ]);
      }
    }()
        .container(
          decoration: BoxDecoration(
            border: Border.all(color: colour),
          ),
        )
        .gestureDetector(onTap: () => setStyle(style))
        .aspectRatio(16 / 9)
        .padding(const EdgeInsets.all(1));
  }
}

@immutable
class StyleControls extends StatelessWidget {
  final Style style;
  final void Function(Style) setStyle;

  const StyleControls({
    super.key,
    required this.style,
    required this.setStyle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final iconWidth = constraints.maxWidth / 9;
      return Column(children: [
        Row(children: [
          const Spacer(),
          StyleControl(
            style: Style.topLines,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          const Spacer(),
        ]),
        Row(children: [
          const Spacer(),
          StyleControl(
            style: Style.leftQuarter,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.leftThird,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.leftHalf,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.leftTwoThirds,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.fullScreen,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.rightTwoThirds,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.rightHalf,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.rightThird,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.rightQuarter,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          const Spacer(),
        ]),
        Row(children: [
          StyleControl(
            style: Style.none,
            selected: style,
            setStyle: setStyle,
          )
              .sized(width: iconWidth)
              .aligned(AlignmentDirectional.bottomStart)
              .expanded(),
          StyleControl(
            style: Style.bottomLines,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.bottomParagraphs,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          const Spacer(),
        ]),
      ]);
    }).padding(const EdgeInsets.all(8));
  }
}

@immutable
class OptionalStyleControls extends StatelessWidget {
  final Style? style;
  final void Function(Style?) setStyle;

  const OptionalStyleControls({
    super.key,
    required this.style,
    required this.setStyle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final iconWidth = constraints.maxWidth / 9;
      return Column(children: [
        Row(children: [
          const Spacer(),
          StyleControl(
            style: Style.topLines,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          const Spacer(),
        ]),
        Row(children: [
          const Spacer(),
          StyleControl(
            style: Style.leftQuarter,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.leftThird,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.leftHalf,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.leftTwoThirds,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.fullScreen,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.rightTwoThirds,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.rightHalf,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.rightThird,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.rightQuarter,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          const Spacer(),
        ]),
        Row(children: [
          StyleControl(
            style: Style.none,
            selected: style,
            setStyle: setStyle,
          )
              .sized(width: iconWidth)
              .aligned(AlignmentDirectional.bottomStart)
              .expanded(),
          StyleControl(
            style: Style.bottomLines,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          StyleControl(
            style: Style.bottomParagraphs,
            selected: style,
            setStyle: setStyle,
          ).sized(width: iconWidth),
          Text(
            "Default",
            style: TextStyle(
              color: style == null
                  ? ColourPalette.of(context).active
                  : ColourPalette.of(context).foreground,
            ),
          )
              .gestureDetector(onTap: () => setStyle(null))
              .aligned(AlignmentDirectional.bottomEnd)
              .expanded(),
        ]),
      ]);
    }).padding(const EdgeInsets.all(8));
  }
}

@immutable
class CopyableText extends StatefulWidget {
  final String text;

  const CopyableText(this.text, {super.key});

  @override
  CopyableTextState createState() => CopyableTextState();
}

class CopyableTextState extends State<CopyableText>
    with SingleTickerProviderStateMixin {
  late final AnimationController opacityController;
  final Animatable<double> opacity = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
  ]);

  @override
  void initState() {
    super.initState();

    opacityController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_on_clipboard,
              color: ColourPalette.of(context).active,
            ).padding(const EdgeInsets.all(2)),
            Text(
              widget.text,
              style: TextStyle(
                color: ColourPalette.of(context).active,
                decoration: TextDecoration.underline,
              ),
            ).padding(const EdgeInsets.all(2)),
          ],
        ),
        Text(
          "Copied",
          style: TextStyle(
            color: ColourPalette.of(context).active,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        )
            .container(
              color: ColourPalette.of(context).background,
            )
            .opacity(opacity.evaluate(opacityController))
            .positionedFill,
      ],
    ).gestureDetector(onTap: () async {
      await Clipboard.setData(ClipboardData(text: widget.text));
      opacityController.reset();
      opacityController.forward();
    });
  }
}

@immutable
class DisplaySettingsControl extends StatelessWidget {
  final String name;
  final DisplaySettings displaySettings;
  final void Function(DisplaySettings) update;

  const DisplaySettingsControl({
    super.key,
    required this.name,
    required this.displaySettings,
    required this.update,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      StyleControls(
        style: displaySettings.style,
        setStyle: (style) => update(displaySettings.withStyle(style)),
      ),
      BCForm<DisplaySettings>(
        value: displaySettings,
        onChange: update,
        backgroundColour: ColourPalette.of(context).background,
        fields: [
          BCColourFormField(
            label: const Text('Background:'),
            getter: (displaySettings) => displaySettings.backgroundColour,
            setter: (displaySettings) => displaySettings.withBackgroundColour,
          ),
          BCColourFormField(
            label: const Text('Text Colour:'),
            getter: (displaySettings) => displaySettings.textColour,
            setter: (displaySettings) => displaySettings.withTextColour,
          ),
          BCTextFormField(
            label: const Text('Font Family:'),
            getter: (displaySettings) => displaySettings.fontFamily,
            setter: (displaySettings) => displaySettings.withFontFamily,
            maxLines: 1,
          ),
          BCDoubleFormField(
            label: const Text('Title Size:'),
            getter: (displaySettings) => displaySettings.titleSize,
            setter: (displaySettings) => displaySettings.withTitleSize,
          ),
          BCDoubleFormField(
            label: const Text('Subtitle Size:'),
            getter: (displaySettings) => displaySettings.subtitleSize,
            setter: (displaySettings) => displaySettings.withSubtitleSize,
          ),
          BCDoubleFormField(
            label: const Text('Body Size:'),
            getter: (displaySettings) => displaySettings.bodySize,
            setter: (displaySettings) => displaySettings.withBodySize,
          ),
        ],
      ),
      FutureBuilder(
        future: NetworkInterface.list(
          includeLoopback: true,
          includeLinkLocal: true,
        ),
        builder: (context, interfaces) {
          if (interfaces.data case final interfaces?) {
            return Column(
              children: interfaces
                  .expand((interface) => interface.addresses)
                  .where((address) => address.type == InternetAddressType.IPv4)
                  .map(
                (address) {
                  final url = 'http://${address.address}:8080/?name=$name';
                  return CopyableText(url);
                },
              ).toList(growable: false),
            ).padding(const EdgeInsets.all(5));
          } else if (interfaces.error case final error?) {
            return Text('Error loading URLs: $error');
          } else {
            return const Text('Loading URLs');
          }
        },
      )
    ]);
  }
}

@immutable
class OptionalDisplaySettingsControl extends StatelessWidget {
  final OptionalDisplaySettings displaySettings;
  final void Function(OptionalDisplaySettings) update;
  final DisplaySettings defaultSettings;

  const OptionalDisplaySettingsControl({
    super.key,
    required this.displaySettings,
    required this.update,
    required this.defaultSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      OptionalStyleControls(
        style: displaySettings.style,
        setStyle: (style) => update(displaySettings.withStyle(style)),
      ),
      BCForm<OptionalDisplaySettings>(
          value: displaySettings,
          onChange: update,
          backgroundColour: ColourPalette.of(context).background,
          fields: [
            BCOptionalColourFormField(
              label: const Text('Background:'),
              getter: (displaySettings) => displaySettings.backgroundColour,
              default_: defaultSettings.backgroundColour,
              setter: (displaySettings) => displaySettings.withBackgroundColour,
            ),
            BCOptionalColourFormField(
              label: const Text('Text Colour:'),
              getter: (displaySettings) => displaySettings.textColour,
              default_: defaultSettings.textColour,
              setter: (displaySettings) => displaySettings.withBackgroundColour,
            ),
            BCOptionalTextFormField(
              label: const Text('Font Family:'),
              getter: (displaySettings) => displaySettings.fontFamily,
              default_: defaultSettings.fontFamily,
              setter: (displaySettings) => displaySettings.withFontFamily,
            ),
            BCOptionalDoubleFormField(
              label: const Text('Title Size:'),
              getter: (displaySettings) => displaySettings.titleSize,
              default_: defaultSettings.titleSize,
              setter: (displaySettings) => displaySettings.withTitleSize,
            ),
            BCOptionalDoubleFormField(
              label: const Text('Subtitle Size:'),
              getter: (displaySettings) => displaySettings.subtitleSize,
              default_: defaultSettings.subtitleSize,
              setter: (displaySettings) => displaySettings.withSubtitleSize,
            ),
            BCOptionalDoubleFormField(
              label: const Text('Body Size:'),
              getter: (displaySettings) => displaySettings.bodySize,
              default_: defaultSettings.bodySize,
              setter: (displaySettings) => displaySettings.withBodySize,
            ),
          ]),
    ]);
  }
}

@immutable
class _FoldingRow extends StatefulWidget {
  final Widget header;
  final Widget body;
  final bool selected;
  final void Function() toggleSelect;

  const _FoldingRow({
    required this.header,
    required this.body,
    required this.selected,
    required this.toggleSelect,
  });

  @override
  createState() => _FoldingRowState();
}

class _FoldingRowState extends State<_FoldingRow>
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
  void didUpdateWidget(covariant _FoldingRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.selected) {
      openAnimation.forward();
    } else {
      openAnimation.reverse();
    }
  }

  @override
  void dispose() {
    openAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        widget.header,
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
                ? ColourPalette.of(context).active
                : Colors.transparent,
          )
          .gestureDetector(onTap: widget.toggleSelect),
      widget.body.sizeTransition(
        sizeFactor: openAnimation,
      ),
    ]);
  }
}

@immutable
class DisplaySettingsPanel extends StatefulWidget {
  final BuiltMap<String, DisplaySettings> displaySettings;
  final void Function(BuiltMap<String, DisplaySettings>) update;

  const DisplaySettingsPanel({
    super.key,
    required this.displaySettings,
    required this.update,
  });

  @override
  createState() => _DisplaySettingsPanelState();
}

class _DisplaySettingsPanelState extends State<DisplaySettingsPanel> {
  String? selected;
  final newOutputNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ...widget.displaySettings.entries.map((entry) {
          return _FoldingRow(
            header: Text(entry.key),
            body: DisplaySettingsControl(
              name: entry.key,
              displaySettings: entry.value,
              update: (newSettings) => widget.update(
                widget.displaySettings
                    .rebuild((builder) => builder[entry.key] = newSettings),
              ),
            )
                .container(color: ColourPalette.of(context).secondaryBackground)
                .padding(const EdgeInsets.only(left: 16, bottom: 8)),
            selected: selected == entry.key,
            toggleSelect: () {
              if (selected == entry.key) {
                setState(() => selected = null);
              } else {
                setState(() => selected = entry.key);
              }
            },
          );
        }),
        Row(children: [
          Icon(
            CupertinoIcons.add,
            color: ColourPalette.of(context).foreground,
          )
              .gestureDetector(
                onTap: () => widget.update(
                  widget.displaySettings.rebuild(
                    (settingsBuilder) {
                      settingsBuilder.addAll({
                        newOutputNameController.text:
                            const DisplaySettings.default_(),
                      });
                      newOutputNameController.text = '';
                    },
                  ),
                ),
              )
              .padding(const EdgeInsets.only(left: 5, top: 5, bottom: 5)),
          CupertinoTextFormFieldRow(
            controller: newOutputNameController,
            padding: const EdgeInsets.all(0),
            style: ColourPalette.of(context).bodyStyle,
            maxLines: 1,
            cursorColor: ColourPalette.of(context).foreground,
            placeholder: 'New',
            placeholderStyle: TextStyle(
              color: ColourPalette.of(context).secondaryForeground,
            ),
          ).expanded(),
        ])
            .container(
              decoration: ShapeDecoration(
                shape: StadiumBorder(
                  side: BorderSide(color: ColourPalette.of(context).foreground),
                ),
              ),
            )
            .padding(const EdgeInsets.all(8)),
      ],
    );
  }
}

@immutable
class OptionalDisplaySettingsPanel extends StatefulWidget {
  final BuiltMap<String, OptionalDisplaySettings> displaySettings;
  final void Function(BuiltMap<String, OptionalDisplaySettings>) update;
  final BuiltMap<String, DisplaySettings> defaultSettings;

  const OptionalDisplaySettingsPanel({
    super.key,
    required this.displaySettings,
    required this.update,
    required this.defaultSettings,
  });

  @override
  createState() => _OptionalDisplaySettingsPanelState();
}

class _OptionalDisplaySettingsPanelState
    extends State<OptionalDisplaySettingsPanel> {
  String? selected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: widget.displaySettings.entries.map((entry) {
        return _FoldingRow(
          header: Text(entry.key),
          body: OptionalDisplaySettingsControl(
            displaySettings: entry.value,
            update: (newSettings) => widget.update(
              widget.displaySettings
                  .rebuild((builder) => builder[entry.key] = newSettings),
            ),
            defaultSettings: widget.defaultSettings[entry.key] ??
                const DisplaySettings.default_(),
          )
              .container(color: ColourPalette.of(context).secondaryBackground)
              .padding(const EdgeInsets.only(left: 16, bottom: 8)),
          selected: selected == entry.key,
          toggleSelect: () {
            if (selected == entry.key) {
              setState(() => selected = null);
            } else {
              setState(() => selected = entry.key);
            }
          },
        );
      }).toList(growable: false),
    );
  }
}
