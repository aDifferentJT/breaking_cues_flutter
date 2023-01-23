import 'package:built_collection/built_collection.dart';
import 'package:client/packed_button_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_utils/widget_modifiers.dart';

import 'colours.dart';

@immutable
class _Input<T> extends StatefulWidget {
  final BCFormField<T> field;
  final T value;
  final void Function(T) onChange;
  final Color backgroundColour;

  const _Input({
    super.key,
    required this.field,
    required this.value,
    required this.onChange,
    required this.backgroundColour,
  });

  @override
  createState() => _InputState<T>();
}

class _InputState<T> extends State<_Input<T>> {
  bool isInvalid = false;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      widget.field
          ._input(
            context: context,
            value: widget.value,
            onChange: (newValue) {
              setState(() => isInvalid = newValue == null);
              if (newValue != null) {
                widget.onChange(newValue);
              }
            },
            backgroundColour: widget.backgroundColour,
          )
          .expanded(),
      Icon(
        CupertinoIcons.exclamationmark_circle,
        color: ColourPalette.of(context).danger,
      ).offstage(!isInvalid),
    ]);
  }
}

@immutable
abstract class BCFormField<T> {
  final Widget label;

  const BCFormField({
    required this.label,
  });

  Widget _input({
    required BuildContext context,
    required T value,
    required void Function(T?) onChange,
    required final Color backgroundColour,
  });

  TableRow buildRow({
    required BuildContext context,
    required T value,
    required void Function(T) onChange,
    required final Color backgroundColour,
  }) =>
      TableRow(children: [
        label
            .aligned(AlignmentDirectional.centerEnd)
            .padding(const EdgeInsets.only(left: 4)),
        _Input(
          field: this,
          value: value,
          onChange: onChange,
          backgroundColour: backgroundColour,
        ),
      ]);
}

@immutable
class BCTextFormField<T> extends BCFormField<T> {
  final String Function(T) getter;
  final T? Function(String) Function(T) setter;
  final bool autofocus;
  final void Function()? onTap;

  const BCTextFormField({
    required super.label,
    required this.getter,
    required this.setter,
    this.autofocus = false,
    this.onTap,
  });

  @override
  Widget _input({
    required BuildContext context,
    required T value,
    required void Function(T?) onChange,
    required final Color backgroundColour,
  }) {
    return CupertinoTextFormFieldRow(
      padding: const EdgeInsets.all(2),
      initialValue: getter(value),
      style: ColourPalette.of(context).bodyStyle,
      autofocus: autofocus,
      maxLines: null,
      onChanged: (text) => onChange(setter(value)(text)),
      onTap: onTap,
      cursorColor: ColourPalette.of(context).foreground,
    );
  }
}

@immutable
class BCIntFormField<T> extends BCTextFormField<T> {
  BCIntFormField({
    required super.label,
    required int Function(T) getter,
    required T Function(int) Function(T) setter,
    super.autofocus = false,
    super.onTap,
  }) : super(
          getter: (value) => getter(value).toString(),
          setter: (value) => (text) {
            final x = int.tryParse(text);
            if (x == null) {
              return null;
            }
            return setter(value)(x);
          },
        );
}

@immutable
class BCRadioOption<U> {
  final U value;
  final Widget child;
  final Color colour;

  const BCRadioOption({
    required this.value,
    required this.child,
    required this.colour,
  });
}

@immutable
class BCTickBoxFormField<T> extends BCFormField<T> {
  final bool Function(T) getter;
  final T? Function(bool) Function(T) setter;

  const BCTickBoxFormField({
    required super.label,
    required this.getter,
    required this.setter,
  });

  @override
  Widget _input({
    required BuildContext context,
    required T value,
    required void Function(T?) onChange,
    required final Color backgroundColour,
  }) {
    return Checkbox(
      value: getter(value),
      onChanged: (ticked) => onChange(setter(value)(ticked ?? getter(value))),
    ).aligned(AlignmentDirectional.centerStart);
  }
}

@immutable
class BCRadioFormField<T, U> extends BCFormField<T> {
  final U Function(T) getter;
  final T? Function(U) Function(T) setter;
  final BuiltList<BCRadioOption<U>> options;

  const BCRadioFormField({
    required super.label,
    required this.getter,
    required this.setter,
    required this.options,
  });

  @override
  Widget _input({
    required BuildContext context,
    required T value,
    required void Function(T?) onChange,
    required final Color backgroundColour,
  }) {
    return PackedButtonRow(
        buttons: options
            .map(
              (option) => PackedButton(
                child: option.child,
                colour: option.colour,
                filled: option.value == getter(value),
                filledChildColour: backgroundColour,
                onTap: () => onChange(setter(value)(option.value)),
              ),
            )
            .toBuiltList());
  }
}

@immutable
class BCForm<T> extends StatelessWidget {
  final T value;
  final void Function(T) onChange;
  final Color backgroundColour;
  final BuiltList<BCFormField<T>> fields;

  BCForm({
    super.key,
    required this.value,
    required this.onChange,
    required this.backgroundColour,
    required Iterable<BCFormField<T>> fields,
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
              value: value,
              onChange: onChange,
              backgroundColour: backgroundColour,
            ),
          )
          .toList(),
    );
  }
}
