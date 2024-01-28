import 'dart:async';

import 'package:core/pubsub.dart';
import 'package:flutter/widgets.dart';

abstract class _PubSubBuilderBase<T> extends StatefulWidget {
  PubSub<T> get pubSub;
  Widget build(BuildContext context, T? value);

  const _PubSubBuilderBase({super.key});

  @override
  State<StatefulWidget> createState() => _PubSubBuilderBaseState();
}

class _PubSubBuilderBaseState<T> extends State<_PubSubBuilderBase<T>> {
  T? value;

  late StreamSubscription<T> subscription;

  @override
  void initState() {
    super.initState();
    subscription =
        widget.pubSub.subscribe((newValue) => setState(() => value = newValue));
  }

  @override
  void didUpdateWidget(covariant _PubSubBuilderBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pubSub != oldWidget.pubSub) {
      subscription.cancel();
      subscription = widget.pubSub
          .subscribe((newValue) => setState(() => value = newValue));
    }
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, value);
  }
}

class PubSubBuilder<T> extends _PubSubBuilderBase<T> {
  @override
  final PubSub<T> pubSub;

  final Widget Function(BuildContext context, T? value) builder;

  const PubSubBuilder({super.key, required this.pubSub, required this.builder});

  @override
  Widget build(BuildContext context, T? value) => builder(context, value);
}
