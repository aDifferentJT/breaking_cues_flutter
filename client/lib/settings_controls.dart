import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:core/deck.dart';
import 'package:flutter_utils/widget_modifiers.dart';
import 'package:output/colour_to_flutter.dart';

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
    final colour =
        style == selected ? CupertinoColors.activeBlue : Colors.white;
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
              color: style == null ? CupertinoColors.activeBlue : Colors.white,
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

String _colourToString(Color colour) =>
    "${colour.red.toRadixString(16).padLeft(2, '0')}"
    "${colour.green.toRadixString(16).padLeft(2, '0')}"
    "${colour.blue.toRadixString(16).padLeft(2, '0')}"
    "${colour.alpha.toRadixString(16).padLeft(2, '0')}";

@immutable
class ColourControl extends StatefulWidget {
  final String label;
  final Color colour;
  final void Function(Color) setColour;

  const ColourControl({
    super.key,
    required this.label,
    required this.colour,
    required this.setColour,
  });

  @override
  createState() => _ColourControlState();
}

class _ColourControlState extends State<ColourControl> {
  final _controller = TextEditingController();

  void updateText() {
    _controller.text = _colourToString(widget.colour);
  }

  @override
  void initState() {
    super.initState();
    updateText();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ColourControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateText();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.label).aligned(AlignmentDirectional.centerStart).expanded(),
        CupertinoTextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white, fontFamily: "Courier"),
          onSubmitted: (valueStr) {
            if (valueStr.length == 8) {
              widget.setColour(Color.fromARGB(
                int.parse(valueStr.substring(6, 8), radix: 16),
                int.parse(valueStr.substring(0, 2), radix: 16),
                int.parse(valueStr.substring(2, 4), radix: 16),
                int.parse(valueStr.substring(4, 6), radix: 16),
              ));
            }
          },
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp("[0-9a-fA-F]")),
          ],
        ).expanded(),
      ],
    ).padding(const EdgeInsets.all(8));
  }
}

@immutable
class OptionalColourControl extends StatefulWidget {
  final String label;
  final Color? colour;
  final Color defaultColour;
  final void Function(Color?) setColour;

  const OptionalColourControl({
    super.key,
    required this.label,
    required this.colour,
    required this.defaultColour,
    required this.setColour,
  });

  @override
  createState() => _OptionalColourControlState();
}

class _OptionalColourControlState extends State<OptionalColourControl> {
  final _controller = TextEditingController();

  void updateText() {
    _controller.text = _colourToString(widget.colour ?? widget.defaultColour);
  }

  @override
  void initState() {
    super.initState();
    updateText();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OptionalColourControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateText();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.label).aligned(AlignmentDirectional.centerStart).expanded(),
        CupertinoTextField(
          controller: _controller,
          style: TextStyle(
            color: widget.colour != null
                ? CupertinoColors.activeBlue
                : Colors.white,
            fontFamily: "Courier",
          ),
          onSubmitted: (valueStr) {
            if (valueStr.length == 8) {
              widget.setColour(Color.fromARGB(
                int.parse(valueStr.substring(6, 8), radix: 16),
                int.parse(valueStr.substring(0, 2), radix: 16),
                int.parse(valueStr.substring(2, 4), radix: 16),
                int.parse(valueStr.substring(4, 6), radix: 16),
              ));
            }
          },
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp("[0-9a-fA-F]")),
          ],
        ).expanded(),
        Icon(
          Icons.restore,
          color: widget.colour == null ? CupertinoColors.activeBlue : null,
        )
            .gestureDetector(onTap: () => widget.setColour(null))
            .padding(const EdgeInsets.all(4)),
      ],
    ).padding(const EdgeInsets.all(8));
  }
}

@immutable
class SizeControl extends StatefulWidget {
  final String label;
  final double size;
  final void Function(double) setSize;

  const SizeControl({
    super.key,
    required this.label,
    required this.size,
    required this.setSize,
  });

  @override
  createState() => _SizeControlState();
}

class _SizeControlState extends State<SizeControl> {
  final _controller = TextEditingController();

  void updateText() {
    _controller.text = "${widget.size}";
  }

  @override
  void initState() {
    super.initState();
    updateText();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SizeControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateText();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.label).aligned(AlignmentDirectional.centerStart).expanded(),
        CupertinoTextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          onSubmitted: (valueStr) {
            widget.setSize(double.parse(valueStr));
          },
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp("[0-9\\.]")),
          ],
        ).expanded(),
      ],
    ).padding(const EdgeInsets.all(8));
  }
}

@immutable
class OptionalSizeControl extends StatefulWidget {
  final String label;
  final double? size;
  final double defaultSize;
  final void Function(double?) setSize;

  const OptionalSizeControl({
    super.key,
    required this.label,
    required this.size,
    required this.defaultSize,
    required this.setSize,
  });

  @override
  createState() => _OptionalSizeControlState();
}

class _OptionalSizeControlState extends State<OptionalSizeControl> {
  final _controller = TextEditingController();

  void updateText() {
    _controller.text = "${widget.size ?? widget.defaultSize}";
  }

  @override
  void initState() {
    super.initState();
    updateText();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OptionalSizeControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    updateText();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.label).aligned(AlignmentDirectional.centerStart).expanded(),
        CupertinoTextField(
          controller: _controller,
          style: TextStyle(
            color:
                widget.size != null ? CupertinoColors.activeBlue : Colors.white,
          ),
          onSubmitted: (valueStr) {
            widget.setSize(double.parse(valueStr));
          },
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp("[0-9\\.]")),
          ],
        ).expanded(),
        Icon(
          Icons.restore,
          color: widget.size == null ? CupertinoColors.activeBlue : null,
        )
            .gestureDetector(onTap: () => widget.setSize(null))
            .padding(const EdgeInsets.all(4)),
      ],
    ).padding(const EdgeInsets.all(8));
  }
}

@immutable
class DisplaySettingsControl extends StatelessWidget {
  final DisplaySettings displaySettings;
  final void Function(DisplaySettings) update;

  const DisplaySettingsControl({
    super.key,
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
      ColourControl(
        label: "Background:",
        colour: displaySettings.backgroundColour.flutter,
        setColour: (colour) =>
            update(displaySettings.withBackgroundColour(colour.colour)),
      ),
      ColourControl(
        label: "Text Colour:",
        colour: displaySettings.textColour.flutter,
        setColour: (colour) =>
            update(displaySettings.withTextColour(colour.colour)),
      ),
      SizeControl(
        label: "Title Size:",
        size: displaySettings.titleSize,
        setSize: (size) => update(displaySettings.withTitleSize(size)),
      ),
      SizeControl(
        label: "Subtitle Size:",
        size: displaySettings.subtitleSize,
        setSize: (size) => update(displaySettings.withSubtitleSize(size)),
      ),
      SizeControl(
        label: "Body Size:",
        size: displaySettings.bodySize,
        setSize: (size) => update(displaySettings.withBodySize(size)),
      ),
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
      OptionalColourControl(
        label: "Background:",
        colour: displaySettings.backgroundColour?.flutter,
        defaultColour: defaultSettings.backgroundColour.flutter,
        setColour: (colour) =>
            update(displaySettings.withBackgroundColour(colour?.colour)),
      ),
      OptionalColourControl(
        label: "Text Colour:",
        colour: displaySettings.textColour?.flutter,
        defaultColour: defaultSettings.textColour.flutter,
        setColour: (colour) =>
            update(displaySettings.withTextColour(colour?.colour)),
      ),
      OptionalSizeControl(
        label: "Title Size:",
        size: displaySettings.titleSize,
        defaultSize: defaultSettings.titleSize,
        setSize: (size) => update(displaySettings.withTitleSize(size)),
      ),
      OptionalSizeControl(
        label: "Subtitle Size:",
        size: displaySettings.subtitleSize,
        defaultSize: defaultSettings.subtitleSize,
        setSize: (size) => update(displaySettings.withSubtitleSize(size)),
      ),
      OptionalSizeControl(
        label: "Body Size:",
        size: displaySettings.bodySize,
        defaultSize: defaultSettings.bodySize,
        setSize: (size) => update(displaySettings.withBodySize(size)),
      ),
    ]);
  }
}
