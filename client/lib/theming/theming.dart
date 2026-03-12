import 'package:flutter/material.dart';

class ThemeProvider {
  static ThemeData forBrightness(Brightness brightness, {Color? seedColor}) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? Colors.deepPurple,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? Colors.black
          : Color.fromARGB(255, 241, 241, 241),
    );
  }

  static ThemeData get dark {
    return forBrightness(Brightness.dark);
  }

  static ThemeData get light {
    return forBrightness(Brightness.light);
  }
}
