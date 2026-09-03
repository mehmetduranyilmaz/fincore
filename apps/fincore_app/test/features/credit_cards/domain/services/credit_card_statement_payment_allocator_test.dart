import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/services/credit_card_statement_payment_allocator.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'allocates an unlinked September payment to the open August statement',
    () {
      final paid = CreditCardStatementPaymentAllocator.allocate(
        statements: [_statement('august', DateTime(2026, 8, 31), 30000)],
        transactions: [_payment('payment', DateTime(2026, 9, 2), 30000)],
      );

      expect(paid['august'], 30000);
    },
  );

  test(
    'allocates partial unlinked payments to oldest open statements first',
    () {
      final paid = CreditCardStatementPaymentAllocator.allocate(
        statements: [
          _statement('august', DateTime(2026, 8, 31), 30000),
          _statement('september', DateTime(2026, 9, 30), 5000),
        ],
        transactions: [_payment('payment', DateTime(2026, 10, 2), 32000)],
      );

      expect(paid, {'august': 30000, 'september': 2000});
    },
  );
}

CreditCardStatement _statement(String id, DateTime date, double amount) =>
    CreditCardStatement(
      id: id,
      creditCardId: 'card-1',
      statementDate: date,
      dueDate: date.add(const Duration(days: 10)),
      createdAt: date,
      lines: [
        CreditCardStatementLine(
          transactionId: 'expense-$id',
          description: id,
          transactionDate: date.subtract(const Duration(days: 1)),
          amount: amount,
        ),
      ],
    );

Transaction _payment(String id, DateTime date, double amount) => Transaction(
  id: id,
  accountId: null,
  creditCardId: 'card-1',
  amount: amount,
  transactionType: TransactionType.income,
  categoryId: null,
  merchant: id,
  note: null,
  transactionDate: date,
  source: TransactionSource.manual,
  isDeleted: false,
  paymentGroupId: 'group-$id',
);
