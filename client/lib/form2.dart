import 'package:built_collection/built_collection.dart';
import 'package:client/colours.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_utils/widget_modifiers.dart';

@immutable
class _Input extends StatelessWidget {
  final BCTextFormField2 field;
  final Color backgroundColour;

  const _Input({
    required this.field,
    required this.backgroundColour,
  });

  @override
  Widget build(BuildContext context) {
    final isValid = field.isValid(field.controller.text);
    return Row(children: [
      field
          ._input(
            context: context,
            backgroundColour: backgroundColour,
          )
          .expanded(),
      Icon(
        CupertinoIcons.exclamationmark_circle,
        color: ColourPalette.of(context).danger,
      ).offstage(isValid),
    ]);
  }
}

@immutable
class BCTextFormField2 {
  final Widget label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  late final bool Function(String) isValid;
  final int? maxLines;

  BCTextFormField2({
    required this.label,
    required this.controller,
    this.focusNode,
    bool Function(String)? isValid,
    required this.maxLines,
  }) : isValid = isValid ?? ((_) => true);

  Widget _input({
    required BuildContext context,
    required final Color backgroundColour,
  }) {
    return CupertinoTextFormFieldRow(
      controller: controller,
      padding: const EdgeInsets.all(2),
      style: ColourPalette.of(context).bodyStyle,
      maxLines: maxLines,
      cursorColor: ColourPalette.of(context).foreground,
    );
  }

  TableRow buildRow({
    required BuildContext context,
    required Color backgroundColour,
  }) {
    return TableRow(children: [
      label
          .aligned(AlignmentDirectional.centerEnd)
          .padding(const EdgeInsets.only(left: 4)),
      _Input(
        field: this,
        backgroundColour: backgroundColour,
      ),
    ]);
  }
}

@immutable
class BCForm2 extends StatelessWidget {
  final Color backgroundColour;
  final BuiltList<BCTextFormField2> fields;

  BCForm2({
    super.key,
    required this.backgroundColour,
    required Iterable<BCTextFormField2> fields,
  }) : fields = fields.toBuiltList();

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      border: TableBorder(
        horizontalInside:
            BorderSide(color: ColourPalette.of(context).secondaryBackground),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: fields
          .map(
            (field) => field.buildRow(
              context: context,
              backgroundColour: backgroundColour,
            ),
          )
          .toList(),
    );
  }
}
