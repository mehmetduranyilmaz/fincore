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

  test('distinguishes card debt payments from customer card payments', () {
    final cardDebtPayment = _createTransaction(
      accountId: null,
      creditCardId: 'credit-card-1',
      transactionType: TransactionType.income,
      paymentGroupId: 'card-payment-group',
    );
    final customerCardPayment = _createTransaction(
      accountId: null,
      creditCardId: 'credit-card-1',
      transactionType: TransactionType.expense,
      paymentGroupId: 'customer-payment-group',
      customerId: 'customer-1',
      customerBalanceDelta: 100,
    );

    expect(cardDebtPayment.isCreditCardDebtPayment, isTrue);
    expect(customerCardPayment.isCreditCardDebtPayment, isFalse);
    expect(customerCardPayment.isCustomerPayment, isTrue);
  });
}

Transaction _createTransaction({
  required String? accountId,
  required String? creditCardId,
  TransactionType transactionType = TransactionType.expense,
  String? paymentGroupId,
  String? customerId,
  double? customerBalanceDelta,
}) {
  return Transaction(
    id: 'transaction-1',
    accountId: accountId,
    creditCardId: creditCardId,
    amount: 100,
    transactionType: transactionType,
    categoryId: null,
    merchant: 'Test',
    note: null,
    transactionDate: DateTime(2026),
    source: TransactionSource.manual,
    isDeleted: false,
    paymentGroupId: paymentGroupId,
    customerId: customerId,
    customerBalanceDelta: customerBalanceDelta,
  );
}
