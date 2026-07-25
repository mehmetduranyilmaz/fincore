import 'package:fincore_app/core/theme/app_colors.dart';
import 'package:fincore_app/core/theme/app_radius.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static final ThemeData light = _createLightTheme();

  static ThemeData _createLightTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          secondary: AppColors.secondary,
          error: AppColors.error,
          surface: AppColors.surface,
        );
    final inputBorder = OutlineInputBorder(
      borderRadius: AppRadius.mdBorderRadius,
      borderSide: BorderSide(color: colorScheme.outline),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorderRadius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.mdBorderRadius,
          ),
        ),
      ),
    );
  }
}
