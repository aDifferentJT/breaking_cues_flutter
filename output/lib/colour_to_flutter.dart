import 'package:core/deck.dart';
import 'package:flutter/widgets.dart';

extension ColourToFlutter on Colour {
  Color get flutter => Color.fromARGB(a, r, g, b);
}

extension ColourFromFlutter on Color {
  Colour get colour => Colour(a: alpha, r: red, g: green, b: blue);
}
