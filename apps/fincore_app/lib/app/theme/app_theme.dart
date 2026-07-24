import 'package:fincore_app/app/theme/app_colors.dart';
import 'package:fincore_app/app/theme/app_typography.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          secondary: AppColors.secondary,
          error: AppColors.error,
          surface: AppColors.surface,
        ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: AppTypography.textTheme,
  );
}
