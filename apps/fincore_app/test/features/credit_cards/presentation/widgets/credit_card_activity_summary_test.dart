import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_activity_summary.dart';
import 'package:fincore_app/features/credit_cards/presentation/widgets/credit_card_activity_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('all three activity summaries are actionable', (tester) async {
    var statements = 0;
    var currentPeriod = 0;
    var futureInstallments = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreditCardActivitySummaryView(
            summary: const CreditCardActivitySummary(
              statementAmount: 1000,
              currentPeriodAmount: 2000,
              futureInstallmentAmount: 3000,
            ),
            currencyCode: 'TRY',
            onStatementsTap: () => statements++,
            onCurrentPeriodTap: () => currentPeriod++,
            onFutureInstallmentsTap: () => futureInstallments++,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Ekstreler'));
    await tester.tap(find.byTooltip('Dönem İçi Hareketler'));
    await tester.tap(find.byTooltip('Gelecek Aylardaki Taksitler'));

    expect(statements, 1);
    expect(currentPeriod, 1);
    expect(futureInstallments, 1);
  });
}
