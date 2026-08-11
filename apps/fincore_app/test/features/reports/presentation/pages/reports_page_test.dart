import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/features/app_shell/presentation/pages/reports_page.dart';
import 'package:fincore_app/features/reports/domain/entities/expense_category_report.dart';
import 'package:fincore_app/features/reports/domain/entities/expense_report_period.dart';
import 'package:fincore_app/features/reports/presentation/providers/expense_category_report_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders category totals and expense drill-down', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseCategoryReportProvider.overrideWith((ref) async => _report),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ReportsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Harcama Raporları'), findsOneWidget);
    expect(find.text('Aylık'), findsOneWidget);
    expect(find.text('Yıllık'), findsOneWidget);
    expect(find.text('Toplam Harcama'), findsOneWidget);
    expect(find.text('300,00 ₺'), findsNWidgets(2));
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('2 işlem • %100,0'), findsOneWidget);

    await tester.tap(find.text('Market'));
    await tester.pumpAndSettle();
    expect(find.text('Market alışverişi'), findsOneWidget);
    expect(find.text('Fırın'), findsOneWidget);
  });
}

final _report = ExpenseCategoryReport(
  period: ExpenseReportPeriod.month(DateTime(2026, 8)),
  currencies: [
    CurrencyExpenseReport(
      currencyCode: 'TRY',
      totalAmount: 300,
      transactionCount: 2,
      categories: [
        CategoryExpenseBreakdown(
          categoryId: 'category-grocery',
          name: 'Groceries',
          icon: 'shopping_cart',
          color: 0xFF2E7D32,
          amount: 300,
          percentage: 1,
          transactionCount: 2,
          transactions: [
            ExpenseReportTransaction(
              id: 'transaction-1',
              description: 'Market alışverişi',
              date: DateTime(2026, 8, 8),
              amount: 200,
            ),
            ExpenseReportTransaction(
              id: 'transaction-2',
              description: 'Fırın',
              date: DateTime(2026, 8, 5),
              amount: 100,
            ),
          ],
        ),
      ],
    ),
  ],
);
