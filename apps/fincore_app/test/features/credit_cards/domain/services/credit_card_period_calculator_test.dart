import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/services/credit_card_period_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('statementPeriod', () {
    test(
      'a month-end card statement cut on the 1st closes the prior month',
      () {
        expect(
          CreditCardPeriodCalculator.statementPeriod(
            statementDate: DateTime(2026, 10, 1),
            statementDay: 31,
          ),
          DateTime(2026, 9),
        );
        expect(
          CreditCardPeriodCalculator.statementPeriod(
            statementDate: DateTime(2026, 8, 30),
            statementDay: 31,
          ),
          DateTime(2026, 8),
        );
      },
    );

    test('a statement cut on its statement day keeps its own month', () {
      expect(
        CreditCardPeriodCalculator.statementPeriod(
          statementDate: DateTime(2026, 10, 20),
          statementDay: 20,
        ),
        DateTime(2026, 10),
      );
    });
  });

  group('transactionPeriod', () {
    final septemberStatement = CreditCardStatement(
      id: 'september',
      creditCardId: 'kuveyt',
      statementDate: DateTime(2026, 10, 1),
      dueDate: DateTime(2026, 10, 12),
      createdAt: DateTime(2026, 10, 1),
      lines: [
        CreditCardStatementLine(
          transactionId: 'on-statement',
          description: 'Market',
          transactionDate: DateTime(2026, 9, 20),
          amount: 100,
        ),
      ],
    );

    DateTime periodOf(String id, DateTime date) =>
        CreditCardPeriodCalculator.transactionPeriod(
          transactionId: id,
          transactionDate: date,
          statementDay: 31,
          statements: [septemberStatement],
        );

    test('statement lines follow the statement period', () {
      expect(
        periodOf('on-statement', DateTime(2026, 9, 20)),
        DateTime(2026, 9),
      );
    });

    test('October spending after the 1 October cut stays in October', () {
      expect(periodOf('october', DateTime(2026, 10, 1)), DateTime(2026, 10));
      expect(periodOf('october', DateTime(2026, 10, 15)), DateTime(2026, 10));
      expect(periodOf('october', DateTime(2026, 10, 31)), DateTime(2026, 10));
      expect(periodOf('november', DateTime(2026, 11, 2)), DateTime(2026, 11));
    });
  });

  group('statement cut on its statement day', () {
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
