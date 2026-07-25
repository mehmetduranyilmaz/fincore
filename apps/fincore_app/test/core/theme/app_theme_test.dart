import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/theme/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses Material 3 and centralized component shapes', () {
    final theme = AppTheme.light;
    final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
    final buttonShape =
        theme.filledButtonTheme.style!.shape!.resolve({})!
            as RoundedRectangleBorder;

    expect(theme.useMaterial3, isTrue);
    expect(cardShape.borderRadius, AppRadius.lgBorderRadius);
    expect(buttonShape.borderRadius, AppRadius.mdBorderRadius);
    expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
  });
}
