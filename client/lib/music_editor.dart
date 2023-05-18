import 'package:built_collection/built_collection.dart';
import 'package:client/colours.dart';

import 'package:core/music.dart';
import 'package:flutter/material.dart';
import 'package:flutter_utils/widget_modifiers.dart';
import 'package:output/music.dart';

@immutable
abstract class _DraggedGlyph {
  const _DraggedGlyph();

  Glyph? glyphAtPitch(final NotePitch pitch);
  Glyph? addTo(Glyph glyph, {required final NotePitch atPitch});
}

@immutable
class _DraggedDeleter extends _DraggedGlyph {
  const _DraggedDeleter();

  @override
  Glyph? glyphAtPitch(final NotePitch pitch) => null;
  @override
  Glyph? addTo(Glyph glyph, {required final NotePitch atPitch}) => null;
}

@immutable
class _PositionIndependentDraggedBaseGlyph extends _DraggedGlyph {
  final Glyph glyph;

  const _PositionIndependentDraggedBaseGlyph(this.glyph);

  @override
  Glyph? glyphAtPitch(NotePitch pitch) => glyph;

  @override
  Glyph? addTo(Glyph glyph, {required NotePitch atPitch}) => glyph;
}

@immutable
class _DraggedNote extends _DraggedGlyph {
  final NoteDuration? duration;

  const _DraggedNote({required this.duration});

  @override
  Glyph? glyphAtPitch(
    NotePitch pitch,
  ) =>
      Chord(
        duration: duration,
        pitches: [pitch].toBuiltSet(),
      );

  @override
  Glyph? addTo(
    Glyph glyph, {
    required NotePitch atPitch,
  }) {
    if (glyph is Chord) {
      if (glyph.duration == duration) {
        return glyph.addPitch(atPitch);
      }
    }
    return glyph;
  }
}

@immutable
class _DraggedAugmentationDot extends _DraggedGlyph {
  const _DraggedAugmentationDot();

  @override
  Glyph? glyphAtPitch(final NotePitch pitch) => null;

  @override
  Glyph? addTo(
    Glyph glyph, {
    required NotePitch atPitch,
  }) {
    if (glyph is Chord) {
      return glyph.addAugmentationDot();
    }
    return glyph;
  }
}

@immutable
class _DraggableGlyphDock extends StatelessWidget {
  final _DraggedGlyph glyph;
  final Iterable<String> smuflNames;

  const _DraggableGlyphDock({
    required this.glyph,
    required this.smuflNames,
  });

  @override
  Widget build(BuildContext context) {
    final sMuFL = SMuFL.of(context);
    return RichText(
      text: sMuFL.textSpan(
        smuflNames,
        style: ColourPalette.of(context).bodyStyle.copyWith(fontSize: 20),
        inline: true,
      ),
      textAlign: TextAlign.center,
    )
        .padding(
          const EdgeInsets.fromLTRB(4, 16, 4, 4),
        )
        .draggable(
          feedback: RichText(
            text: sMuFL.textSpan(
              smuflNames,
              style: ColourPalette.of(context).bodyStyle.copyWith(fontSize: 20),
            ),
          )
              .baseline(baseline: 0.0, baselineType: TextBaseline.ideographic)
              .opacity(0.5),
          data: glyph,
          dragAnchorStrategy: pointerDragAnchorStrategy,
        );
  }
}

@immutable
class MusicEditor extends StatefulWidget {
  final Stave stave;
  final void Function(Stave) onChangeStave;

  const MusicEditor({
    super.key,
    required this.stave,
    required this.onChangeStave,
  });

  @override
  createState() => _MusicEditorState();
}

class _MusicEditorState extends State<MusicEditor> {
  final staveKey = GlobalKey();

  late Stave temporaryStave;

  static const double textSize = 14;
  static const double staveSpacing = 30;

  @override
  void initState() {
    super.initState();

    temporaryStave = widget.stave;
  }

  @override
  void didUpdateWidget(covariant MusicEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    temporaryStave = widget.stave;
  }

  void updateTemporaryStave(
    final DragTargetDetails<_DraggedGlyph> details,
    LaidOutBaseGlyphs laidOutBaseGlyphs,
  ) {
    final staveBox = staveKey.currentContext?.findRenderObject() as RenderBox?;
    if (staveBox != null) {
      final offset = staveBox.globalToLocal(details.offset);
      var indexToTheRight = laidOutBaseGlyphs.glyphs
          .indexWhere((glyph) => glyph.xOffset > offset.dx);
      if (indexToTheRight < 0) {
        indexToTheRight = laidOutBaseGlyphs.glyphs.length;
      }
      final indexToTheLeft = indexToTheRight - 1;
      final inNote =
          (offset.dx - laidOutBaseGlyphs.glyphs[indexToTheLeft].xOffset) <=
              laidOutBaseGlyphs.glyphs[indexToTheLeft].painter.metrics.minWidth;

      if (inNote) {
        if (indexToTheLeft >= 0) {
          final glyph = details.data.addTo(
            widget.stave.baseGlyphs[indexToTheLeft],
            atPitch: NotePitch(
              distanceDownFromCentre:
                  (offset.dy - laidOutBaseGlyphs.ascent) ~/ (staveSpacing / 2) -
                      4,
            ),
          );
          setState(() {
            temporaryStave = widget.stave.rebuildBaseGlyphs(
              (glyphs) {
                if (glyph != null) {
                  glyphs[indexToTheLeft] = glyph;
                } else {
                  glyphs.removeAt(indexToTheLeft);
                }
              },
            );
          });
        }
      } else {
        final glyph = details.data.glyphAtPitch(
          NotePitch(
            distanceDownFromCentre:
                (offset.dy - laidOutBaseGlyphs.ascent) ~/ (staveSpacing / 2) -
                    4,
          ),
        );
        setState(() {
          if (glyph != null) {
            temporaryStave = widget.stave.rebuildBaseGlyphs(
              (glyphs) {
                glyphs.insert(
                  indexToTheRight < 0 ? glyphs.length : indexToTheRight,
                  glyph,
                );
              },
            );
          } else {
            temporaryStave = widget.stave;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final laidOutBaseGlyphsWithoutDragged = LaidOutBaseGlyphs.leftAligned(
      glyphs: widget.stave.baseGlyphs,
      sMuFL: SMuFL.of(context),
      colour: ColourPalette.of(context).foreground,
      textSize: textSize,
      staveSpacing: staveSpacing,
    );
    final laidOutBaseGlyphsWithDragged = LaidOutBaseGlyphs.leftAligned(
      glyphs: temporaryStave.baseGlyphs,
      sMuFL: SMuFL.of(context),
      colour: ColourPalette.of(context).foreground,
      textSize: textSize,
      staveSpacing: staveSpacing,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const [
              _DraggableGlyphDock(
                glyph: _DraggedDeleter(),
                smuflNames: ['noteheadXBlack'],
              ),
              _DraggableGlyphDock(
                glyph: _PositionIndependentDraggedBaseGlyph(TrebleClef()),
                smuflNames: ['gClef'],
              ),
              _DraggableGlyphDock(
                glyph: _PositionIndependentDraggedBaseGlyph(BassClef()),
                smuflNames: ['fClef'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedAugmentationDot(),
                smuflNames: ['augmentationDot'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(duration: null),
                smuflNames: ['noteheadBlack'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(
                  duration: NoteDuration(
                    fractionOfSemibreve: 1,
                  ),
                ),
                smuflNames: ['noteWhole'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(
                  duration: NoteDuration(
                    fractionOfSemibreve: 2,
                  ),
                ),
                smuflNames: ['noteHalfUp'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(
                  duration: NoteDuration(
                    fractionOfSemibreve: 4,
                  ),
                ),
                smuflNames: ['noteQuarterUp'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(
                  duration: NoteDuration(
                    fractionOfSemibreve: 8,
                  ),
                ),
                smuflNames: ['note8thUp'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(
                  duration: NoteDuration(
                    fractionOfSemibreve: 16,
                  ),
                ),
                smuflNames: ['note16thUp'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(
                  duration: NoteDuration(
                    fractionOfSemibreve: 32,
                  ),
                ),
                smuflNames: ['note32ndUp'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(
                  duration: NoteDuration(
                    fractionOfSemibreve: 64,
                  ),
                ),
                smuflNames: ['note64thUp'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(
                  duration: NoteDuration(
                    fractionOfSemibreve: 128,
                  ),
                ),
                smuflNames: ['note128thUp'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(
                  duration: NoteDuration(
                    fractionOfSemibreve: 256,
                  ),
                ),
                smuflNames: ['note256thUp'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(
                  duration: NoteDuration(
                    fractionOfSemibreve: 512,
                  ),
                ),
                smuflNames: ['note512thUp'],
              ),
              _DraggableGlyphDock(
                glyph: _DraggedNote(
                  duration: NoteDuration(
                    fractionOfSemibreve: 1024,
                  ),
                ),
                smuflNames: ['note1024thUp'],
              ),
            ],
          ).sized(height: 50),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DragTarget<_DraggedGlyph>(
            builder: (
              final BuildContext context,
              final List<_DraggedGlyph?> candidateData,
              final List rejectedData,
            ) {
              return StaveWidget(
                laidOutBaseGlyphs: laidOutBaseGlyphsWithDragged,
                key: staveKey,
                colour: ColourPalette.of(context).foreground,
              );
            },
            onMove: (details) {
              updateTemporaryStave(details, laidOutBaseGlyphsWithoutDragged);
            },
            onAcceptWithDetails: (details) {
              updateTemporaryStave(details, laidOutBaseGlyphsWithoutDragged);
              widget.onChangeStave(temporaryStave);
            },
            onLeave: (_) => setState(() => temporaryStave = widget.stave),
          ),
        ),
      ],
    );
  }
}
