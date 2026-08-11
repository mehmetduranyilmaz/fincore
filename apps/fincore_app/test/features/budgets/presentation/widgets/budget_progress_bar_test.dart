import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/theme/app_colors.dart';
import 'package:fincore_app/features/budgets/presentation/widgets/budget_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses primary, warning and error progress colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              BudgetProgressBar(progress: 0.79),
              BudgetProgressBar(progress: 0.8),
              BudgetProgressBar(progress: 1),
            ],
          ),
        ),
      ),
    );

    final indicators = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList(growable: false);

    expect(indicators[0].color, AppTheme.light.colorScheme.primary);
    expect(indicators[1].color, AppColors.warning);
    expect(indicators[2].color, AppTheme.light.colorScheme.error);
  });
}
