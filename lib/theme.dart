import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0B0E13);
  static const surface = Color(0xFF131822);
  static const surface2 = Color(0xFF1A212E);
  static const surfaceHover = Color(0xFF212938);
  static const border = Color(0xFF262F40);
  static const text = Color(0xFFEEF2F7);
  static const textDim = Color(0xFF8B96A8);

  static const tnRed = Color(0xFFE70013);
  static const tnRedLight = Color(0xFFFF4D5E);
  static const gold = Color(0xFFFFD24D);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.tnRed,
      secondary: AppColors.tnRedLight,
      surface: AppColors.surface,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.text),
    ),
  );
}
