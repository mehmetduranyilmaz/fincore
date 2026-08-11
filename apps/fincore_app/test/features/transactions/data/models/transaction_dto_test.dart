import 'package:fincore_app/features/transactions/data/models/transaction_dto.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips payment and customer ledger metadata', () {
    final transaction = Transaction(
      id: 'payment-1',
      accountId: 'account-1',
      creditCardId: null,
      amount: 100,
      transactionType: TransactionType.transfer,
      categoryId: null,
      merchant: 'Tahsilat',
      note: null,
      transactionDate: DateTime(2026, 8, 7),
      source: TransactionSource.manual,
      isDeleted: false,
      paymentGroupId: 'group-1',
      customerId: 'customer-1',
      customerBalanceDelta: -100,
    );

    final restored = TransactionDto.fromJson(
      TransactionDto(transaction).toJson(),
    ).transaction;

    expect(restored, transaction);
  });

  test('reads legacy transactions without payment metadata', () {
    final restored = TransactionDto.fromJson({
      'id': 'legacy',
      'accountId': 'account-1',
      'creditCardId': null,
      'amount': 10,
      'transactionType': 'expense',
      'categoryId': null,
      'merchant': 'Legacy',
      'note': null,
      'transactionDate': '2026-08-07T00:00:00.000',
      'source': 'manual',
      'isDeleted': false,
      'transferGroupId': null,
      'installmentPlanId': null,
      'installmentNumber': null,
      'installmentCount': null,
      'installmentTotalAmount': null,
    }).transaction;

    expect(restored.paymentGroupId, isNull);
    expect(restored.customerId, isNull);
  });
}
