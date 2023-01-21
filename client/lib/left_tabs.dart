import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_utils/widget_modifiers.dart';

@immutable
class TabEntry {
  final Widget icon;
  final Widget body;

  const TabEntry({required this.icon, required this.body});
}

@immutable
class LeftTabs extends StatefulWidget {
  final double tabWidth;
  final bool keepHiddenChildrenAlive;
  final List<TabEntry> children;

  const LeftTabs({
    super.key,
    this.tabWidth = 26,
    required this.keepHiddenChildrenAlive,
    required this.children,
  });

  @override
  createState() => _LeftTabsState();
}

class _LeftTabsState extends State<LeftTabs> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ListView.builder(
        itemCount: widget.children.length,
        itemBuilder: (context, index) => widget.children[index].icon
            .container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: index == selected
                    ? CupertinoColors.darkBackgroundGray
                    : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(4),
                ),
              ),
            )
            .gestureDetector(onTap: () => setState(() => selected = index)),
      )
          .container(
            padding: const EdgeInsets.only(left: 4),
            color: Colors.black,
          )
          .sized(width: widget.tabWidth + 4),
      (widget.keepHiddenChildrenAlive
              ? Stack(
                  children: widget.children
                      .mapIndexed(
                        (index, tabEntry) =>
                            tabEntry.body.offstage(index != selected),
                      )
                      .toList(growable: false),
                )
              : selected < widget.children.length
                  ? widget.children[selected].body
                      .container(key: ValueKey(selected))
                  : const SizedBox.expand())
          .expanded(),
    ]);
  }
}
