import 'package:flutter/cupertino.dart';
import 'package:flutter_utils/widget_modifiers.dart';

class BCTextField extends StatefulWidget {
  final String value;
  final EdgeInsets padding;
  final TextStyle style;
  final int? maxLines;
  final void Function(String) onChanged;
  final void Function()? onTap;
  final Color cursorColour;

  const BCTextField({
    super.key,
    required this.value,
    required this.padding,
    required this.style,
    required this.maxLines,
    required this.onChanged,
    this.onTap,
    required this.cursorColour,
  });

  @override
  createState() => _TextFieldState();
}

class _TextFieldState extends State<BCTextField> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller.text = widget.value;
  }

  @override
  void didUpdateWidget(covariant BCTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    controller.value = controller.value.copyWith(text: widget.value);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTextFormFieldRow(
      controller: controller,
      padding: widget.padding,
      style: widget.style,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      cursorColor: widget.cursorColour,
    );
  }
}
