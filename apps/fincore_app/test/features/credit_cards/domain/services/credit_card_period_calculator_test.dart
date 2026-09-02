import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/services/credit_card_period_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final statement = CreditCardStatement(
    id: 'statement-august',
    creditCardId: 'card-1',
    statementDate: DateTime(2026, 8, 30),
    dueDate: DateTime(2026, 9, 10),
    createdAt: DateTime(2026, 8, 30, 18),
    lines: [
      CreditCardStatementLine(
        transactionId: 'included-on-cutoff',
        description: 'Kesime dahil',
        transactionDate: DateTime(2026, 8, 30),
        amount: 100,
      ),
    ],
  );

  test('29 August stays in the August statement period', () {
    expect(
      _period('before-cutoff', DateTime(2026, 8, 29), statement),
      DateTime(2026, 8),
    );
  });

  test('included cutoff-day transaction stays in August', () {
    expect(
      _period('included-on-cutoff', DateTime(2026, 8, 30), statement),
      DateTime(2026, 8),
    );
  });

  test('transaction after the completed statement moves to September', () {
    expect(
      _period('after-cutoff', DateTime(2026, 8, 31), statement),
      DateTime(2026, 9),
    );
  });

  test('unassigned cutoff-day transaction moves to the new period', () {
    expect(
      _period('created-after-cutoff', DateTime(2026, 8, 30, 20), statement),
      DateTime(2026, 9),
    );
  });
}

DateTime _period(
  String transactionId,
  DateTime transactionDate,
  CreditCardStatement statement,
) {
  return CreditCardPeriodCalculator.transactionPeriod(
    transactionId: transactionId,
    transactionDate: transactionDate,
    statementDay: 30,
    statements: [statement],
  );
}
