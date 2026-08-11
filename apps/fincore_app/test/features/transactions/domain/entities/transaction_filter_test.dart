import 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to no filters', () {
    final filter = TransactionFilter();

    expect(filter.transactionTypes, isEmpty);
    expect(filter.accountId, isNull);
    expect(filter.creditCardId, isNull);
    expect(filter.startDate, isNull);
    expect(filter.endDate, isNull);
    expect(filter.searchText, isEmpty);
    expect(filter.hasFilters, isFalse);
  });

  test('defensively copies transaction types', () {
    final types = {TransactionType.income};
    final filter = TransactionFilter(transactionTypes: types);

    types.add(TransactionType.expense);

    expect(filter.transactionTypes, {TransactionType.income});
    expect(
      () => filter.transactionTypes.add(TransactionType.transfer),
      throwsUnsupportedError,
    );
  });

  test('copyWith supports clearing nullable filters', () {
    final filter = TransactionFilter(
      accountId: 'account-1',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
    );

    final cleared = filter.copyWith(clearAccountId: true, clearDateRange: true);

    expect(cleared.accountId, isNull);
    expect(cleared.startDate, isNull);
    expect(cleared.endDate, isNull);
  });
}
