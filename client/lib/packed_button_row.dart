import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:flutter_utils/widget_modifiers.dart';

void _doNothing() {}
T _identity<T>(T x) => x;

@immutable
class _PackedButtonWidget extends StatefulWidget {
  final PackedButton button;
  final int index;
  final int buttonCount;
  final EdgeInsetsGeometry padding;

  const _PackedButtonWidget(
    this.button, {
    required this.index,
    required this.buttonCount,
    required this.padding,
  });

  @override
  createState() => _PackedButtonWidgetState();
}

class _PackedButtonWidgetState extends State<_PackedButtonWidget> {
  bool depressed = false;

  bool get filled => depressed || widget.button.filled;

  @override
  Widget build(BuildContext context) {
    final BorderRadiusGeometry borderRadius = BorderRadius.horizontal(
      left: widget.index == 0 ? const Radius.circular(5) : Radius.zero,
      right: widget.index == widget.buttonCount - 1
          ? const Radius.circular(5)
          : Radius.zero,
    );
    return widget.button.child
        .defaultTextStyle(
          style: TextStyle(
            color:
                filled ? widget.button.filledChildColour : widget.button.colour,
          ),
        )
        .iconTheme(
          data: IconThemeData(
            color:
                filled ? widget.button.filledChildColour : widget.button.colour,
          ),
        )
        .container(
          decoration: BoxDecoration(
            color: filled ? widget.button.colour : null,
            border: Border.all(
              color: widget.button.colour,
            ),
            borderRadius: borderRadius,
          ),
        )
        .gestureDetector(
          onTap: widget.button.onTap,
          onTapDown: (_) => setState(() => depressed = true),
          onTapUp: (_) => setState(() => depressed = false),
          onTapCancel: () => setState(() => depressed = false),
        )
        .wrap(widget.button.wrapper)
        .padding(widget.padding);
  }
}

@immutable
class PackedButton {
  final Widget child;
  final Color colour;
  final bool filled;
  final Color filledChildColour;
  final void Function() onTap;
  final Widget Function(Widget) wrapper;

  const PackedButton({
    required this.child,
    required this.colour,
    this.filled = false,
    this.filledChildColour = Colors.black,
    this.onTap = _doNothing,
    this.wrapper = _identity,
  });
}

@immutable
class PackedButtonRow extends StatelessWidget {
  final BuiltList<PackedButton> buttons;
  final EdgeInsetsGeometry padding;

  const PackedButtonRow({
    super.key,
    required this.buttons,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: buttons
          .mapIndexed(
            (index, button) => _PackedButtonWidget(
              button,
              index: index,
              buttonCount: buttons.length,
              padding: padding,
            ),
          )
          .toList(),
    );
  }
}
