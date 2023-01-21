import 'package:built_collection/built_collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_utils/widget_modifiers.dart';

@immutable
class _Input<T> extends StatefulWidget {
  final BCFormField<T> field;
  final T value;
  final void Function(T) onChange;

  const _Input({
    super.key,
    required this.field,
    required this.value,
    required this.onChange,
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
            onChange: widget.onChange,
            setInvalid: (newIsInvalid) =>
                setState(() => isInvalid = newIsInvalid),
          )
          .expanded(),
      const Icon(
        CupertinoIcons.exclamationmark_circle,
        color: CupertinoColors.destructiveRed,
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
    required void Function(T) onChange,
    required void Function(bool) setInvalid,
  });

  TableRow buildRow({
    required BuildContext context,
    required T value,
    required void Function(T) onChange,
  }) =>
      TableRow(children: [
        label
            .aligned(AlignmentDirectional.centerEnd)
            .padding(const EdgeInsets.only(left: 4)),
        _Input(
          field: this,
          value: value,
          onChange: onChange,
        ),
      ]);
}

@immutable
abstract class BCTypedFormField<T, U> extends BCFormField<T> {
  final U Function(T) getter;
  final T? Function(U) Function(T) setter;

  const BCTypedFormField({
    required super.label,
    required this.getter,
    required this.setter,
  });
}

@immutable
class BCTextFormField<T> extends BCTypedFormField<T, String> {
  final bool autofocus;
  final void Function()? onTap;

  const BCTextFormField({
    required super.label,
    required super.getter,
    required super.setter,
    this.autofocus = false,
    this.onTap,
  });

  @override
  Widget _input({
    required BuildContext context,
    required T value,
    required void Function(T) onChange,
    required void Function(bool) setInvalid,
  }) {
    return CupertinoTextFormFieldRow(
      padding: const EdgeInsets.all(2),
      initialValue: getter(value),
      style: Theme.of(context).textTheme.bodyMedium,
      autofocus: autofocus,
      maxLines: null,
      onChanged: (text) {
        final newValue = setter(value)(text);
        setInvalid(newValue == null);
        if (newValue != null) {
          onChange(newValue);
        }
      },
      onTap: onTap,
      cursorColor: Colors.white,
    );
  }
}

@immutable
class BCForm<T> extends StatelessWidget {
  final T value;
  final void Function(T) onChange;
  final BuiltList<BCFormField<T>> fields;

  BCForm({
    super.key,
    required this.value,
    required this.onChange,
    required Iterable<BCFormField<T>> fields,
  }) : fields = fields.toBuiltList();

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      border: const TableBorder(
        horizontalInside: BorderSide(color: CupertinoColors.darkBackgroundGray),
      ),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: fields
          .map(
            (field) => field.buildRow(
              context: context,
              value: value,
              onChange: onChange,
            ),
          )
          .toList(),
    );
  }
}
