import 'package:built_collection/built_collection.dart';
import 'package:client/colours.dart';
import 'package:flutter/cupertino.dart';

import 'package:core/music.dart';
import 'package:flutter/material.dart';
import 'package:flutter_utils/widget_modifiers.dart';
import 'package:output/music.dart';

@immutable
class _DraggableGlyphDock extends StatelessWidget {
  final SMuFL smufl;
  final Iterable<String> smuflNames;

  const _DraggableGlyphDock({required this.smufl, required this.smuflNames});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: smufl.textSpan(
        smuflNames,
        style: ColourPalette.of(context).bodyStyle.copyWith(fontSize: 20),
        inline: true,
      ),
      textAlign: TextAlign.center,
    )
        .centered(heightFactor: 5)
        .background(Colors.pink)
        .container(
          alignment: Alignment.center,
          color: Colors.green,
        )
        .aspectRatio(1)
        .padding(const EdgeInsets.all(5))
        .draggable(
          feedback: RichText(
            text: smufl.textSpan(
              smuflNames,
              style: ColourPalette.of(context).bodyStyle.copyWith(fontSize: 20),
            ),
          ).baseline(baseline: 0.0, baselineType: TextBaseline.ideographic),
          dragAnchorStrategy: pointerDragAnchorStrategy,
        );
  }
}

@immutable
class MusicEditor extends StatefulWidget {
  final Stave stave;

  const MusicEditor({super.key, required this.stave});

  @override
  createState() => _MusicEditorState();
}

class _MusicEditorState extends State<MusicEditor> {
  Future<SMuFL> sMuFL = SMuFL.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: sMuFL,
        builder: ((context, sMuFL) {
          if (sMuFL.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _DraggableGlyphDock(
                        smufl: sMuFL.data!,
                        smuflNames: const ['gClef'],
                      ),
                      _DraggableGlyphDock(
                        smufl: sMuFL.data!,
                        smuflNames: const ['fClef'],
                      ),
                    ],
                  ).sized(height: 50),
                ),
                StaveWidget(
                  widget.stave,
                  colour: ColourPalette.of(context).foreground,
                  textSize: 14,
                ).sized(width: 100, height: 50),
              ],
            );
          } else {
            return const CupertinoActivityIndicator();
          }
        }));
  }
}
