import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Button extends StatefulWidget {
  final void Function() onTap;
  final bool? depressed;
  final Color color;
  final Widget child;

  const Button({
    super.key,
    required this.onTap,
    this.depressed,
    this.color = CupertinoColors.activeBlue,
    required this.child,
  });

  @override
  createState() => ButtonState();
}

class ButtonState extends State<Button> {
  bool depressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (details) => setState(() => depressed = true),
      onTapUp: (details) => setState(() => depressed = false),
      onTapCancel: () => setState(() => depressed = false),
      child: Container(
        decoration: BoxDecoration(
          color: (widget.depressed ?? depressed)
              ? widget.color
              : Colors.transparent,
          border: Border.all(color: widget.color),
          borderRadius: const BorderRadius.all(Radius.circular(5)),
        ),
        padding: const EdgeInsets.all(5),
        child: widget.child,
      ),
    );
  }
}
