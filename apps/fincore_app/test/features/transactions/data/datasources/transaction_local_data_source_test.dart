import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('hard deletion persists and releases reference usage', () async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final firstDataSource = TransactionLocalDataSource(storage);
    await firstDataSource.insert(_movement);

    expect(await firstDataSource.hasAnyAccountMovement('account-used'), isTrue);
    expect(
      await firstDataSource.hasAnyCategoryMovement('category-used'),
      isTrue,
    );
    expect(
      await firstDataSource.hasAnyCustomerMovement('customer-used'),
      isTrue,
    );

    await firstDataSource.removeMany({_movement.id});

    final reloadedDataSource = TransactionLocalDataSource(storage);
    expect(
      await reloadedDataSource.getTransactions(TransactionFilter()),
      isEmpty,
    );
    expect(await reloadedDataSource.findById(_movement.id), isNull);
    expect(
      await reloadedDataSource.hasAnyAccountMovement('account-used'),
      isFalse,
    );
    expect(
      await reloadedDataSource.hasAnyCategoryMovement('category-used'),
      isFalse,
    );
    expect(
      await reloadedDataSource.hasAnyCustomerMovement('customer-used'),
      isFalse,
    );
  });
}

final _movement = Transaction(
  id: 'movement-to-delete',
  accountId: 'account-used',
  creditCardId: null,
  amount: 125,
  transactionType: TransactionType.expense,
  categoryId: 'category-used',
  merchant: 'Test expense',
  note: null,
  transactionDate: DateTime(2026, 8, 10),
  source: TransactionSource.manual,
  isDeleted: false,
  customerId: 'customer-used',
  customerBalanceDelta: 125,
);
