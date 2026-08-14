import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('labels a customer payment made by credit card distinctly', () {
    final transaction = Transaction(
      id: 'customer-card-payment',
      accountId: null,
      creditCardId: 'card-1',
      amount: 100,
      transactionType: TransactionType.expense,
      categoryId: null,
      merchant: 'Müşteri ödemesi',
      note: null,
      transactionDate: DateTime(2026, 8, 13),
      source: TransactionSource.manual,
      isDeleted: false,
      paymentGroupId: 'payment-group',
      customerId: 'customer-1',
      customerBalanceDelta: 100,
    );

    expect(TransactionStrings.transactionTypeFor(transaction), 'K.K. ile Ödm');
    expect(transaction.isActualExpense, isFalse);
  });
}
