import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts exactly one account source', () {
    final transaction = _createTransaction(
      accountId: 'account-1',
      creditCardId: null,
    );

    expect(transaction.accountId, 'account-1');
    expect(transaction.creditCardId, isNull);
  });

  test('rejects missing account and credit card sources', () {
    expect(
      () => _createTransaction(accountId: null, creditCardId: null),
      throwsArgumentError,
    );
  });

  test('rejects simultaneous account and credit card sources', () {
    expect(
      () => _createTransaction(
        accountId: 'account-1',
        creditCardId: 'credit-card-1',
      ),
      throwsArgumentError,
    );
  });
}

Transaction _createTransaction({
  required String? accountId,
  required String? creditCardId,
}) {
  return Transaction(
    id: 'transaction-1',
    accountId: accountId,
    creditCardId: creditCardId,
    amount: 100,
    transactionType: TransactionType.expense,
    categoryId: null,
    merchant: 'Test',
    note: null,
    transactionDate: DateTime(2026),
    source: TransactionSource.manual,
    isDeleted: false,
  );
}
