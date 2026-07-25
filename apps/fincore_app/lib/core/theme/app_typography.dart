import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    height: 1.12,
    letterSpacing: -0.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.29,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 1.27,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    headlineMedium: headlineMedium,
    titleLarge: titleLarge,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    labelMedium: labelMedium,
  );
}
