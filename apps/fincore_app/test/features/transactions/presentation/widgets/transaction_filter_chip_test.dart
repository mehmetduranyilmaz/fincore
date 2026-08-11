import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final theme in [
    (name: 'light', data: AppTheme.light),
    (name: 'dark', data: AppTheme.dark),
  ]) {
    testWidgets('uses readable ${theme.name} theme foreground colors', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme.data,
          home: Scaffold(
            body: Column(
              children: [
                TransactionFilterChip(
                  label: 'Gelir',
                  selected: true,
                  onSelected: (_) {},
                ),
                TransactionFilterChip(
                  label: 'Gider',
                  selected: false,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      expect(
        chips.first.labelStyle?.color,
        theme.data.colorScheme.onSecondaryContainer,
      );
      expect(
        chips.last.labelStyle?.color,
        theme.data.colorScheme.onSurfaceVariant,
      );
    });
  }
}
