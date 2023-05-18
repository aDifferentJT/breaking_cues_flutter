import 'package:flutter/widgets.dart';

@immutable
class ColourPalette {
  final Color background;
  final Color secondaryBackground;
  final Color foreground;
  final Color secondaryForeground;
  final Color active;
  final Color secondaryActive;
  final Color success;
  final Color danger;

  const ColourPalette({
    required this.background,
    required this.secondaryBackground,
    required this.foreground,
    required this.secondaryForeground,
    required this.active,
    required this.secondaryActive,
    required this.success,
    required this.danger,
  });

  const ColourPalette.dark()
      : background = const Color(0xFF000000),
        secondaryBackground = const Color(0xFF22202B),
        foreground = const Color(0xFFFFFFFF),
        secondaryForeground = const Color(0xFFAFAFAF),
        active = const Color(0xFF007FFF),
        secondaryActive = const Color(0xFF3F5F7F),
        success = const Color(0xFF0FDF1F),
        danger = const Color(0xFFDF0F1F);

  const ColourPalette.light()
      : background = const Color(0xFFFFFFEF),
        secondaryBackground = const Color(0xFFBFCFDF),
        foreground = const Color(0xFF000000),
        secondaryForeground = const Color(0xFF7F7F7F),
        active = const Color(0xFF2F5FFF),
        secondaryActive = const Color(0xFF7F9FBF),
        success = const Color(0xFF0FDF1F),
        danger = const Color(0xFFDF0F1F);

  TextStyle get headingStyle => TextStyle(color: foreground, fontSize: 24);
  TextStyle get bodyStyle => TextStyle(color: foreground, fontSize: 14);

  @override
  bool operator ==(Object other) =>
      other is ColourPalette &&
      background == other.background &&
      secondaryBackground == other.secondaryBackground &&
      foreground == other.foreground &&
      secondaryForeground == other.secondaryForeground &&
      active == other.active &&
      secondaryActive == other.secondaryActive &&
      danger == other.danger;

  @override
  int get hashCode => Object.hash(
        background,
        secondaryBackground,
        foreground,
        secondaryForeground,
        active,
        secondaryActive,
        danger,
      );

  factory ColourPalette.of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SetColourPalette>()
          ?.colourPalette ??
      const ColourPalette.dark();
}

@immutable
class ColourPaletteTween extends Animatable<ColourPalette> {
  final ColourPalette begin;
  final ColourPalette end;

  const ColourPaletteTween({required this.begin, required this.end});

  @override
  ColourPalette transform(double t) => ColourPalette(
        background: Color.lerp(
          begin.background,
          end.background,
          t,
        )!,
        secondaryBackground: Color.lerp(
          begin.secondaryBackground,
          end.secondaryBackground,
          t,
        )!,
        foreground: Color.lerp(
          begin.foreground,
          end.foreground,
          t,
        )!,
        secondaryForeground: Color.lerp(
          begin.secondaryForeground,
          end.secondaryForeground,
          t,
        )!,
        active: Color.lerp(
          begin.active,
          end.active,
          t,
        )!,
        secondaryActive: Color.lerp(
          begin.secondaryActive,
          end.secondaryActive,
          t,
        )!,
        success: Color.lerp(
          begin.success,
          end.success,
          t,
        )!,
        danger: Color.lerp(
          begin.danger,
          end.danger,
          t,
        )!,
      );
}

@immutable
class SetColourPalette extends InheritedWidget {
  final ColourPalette colourPalette;

  SetColourPalette({
    super.key,
    required this.colourPalette,
    required Widget child,
  }) : super(
          child: DefaultTextStyle(
            style: TextStyle(color: colourPalette.foreground),
            child: child,
          ),
        );

  @override
  bool updateShouldNotify(covariant SetColourPalette oldWidget) =>
      oldWidget.colourPalette != colourPalette;
}
