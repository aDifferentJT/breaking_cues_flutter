import 'package:core/deck.dart';
import 'package:flutter/material.dart';

import 'colour_to_flutter.dart';

extension DisplaySettingsFlutter on DisplaySettings {
  TextStyle get titleStyle => TextStyle(
        inherit: false,
        color: textColour.flutter,
        fontSize: titleSize,
        fontFamily: fontFamily,
        package: 'fonts',
      );

  TextStyle get subtitleStyle => TextStyle(
        inherit: false,
        color: textColour.flutter,
        fontSize: subtitleSize,
        fontFamily: fontFamily,
        package: 'fonts',
      );

  TextStyle get bodyStyle => TextStyle(
        inherit: false,
        color: textColour.flutter,
        fontSize: bodySize,
        fontFamily: fontFamily,
        package: 'fonts',
      );
}
