import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transaction_filter_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updates and resets immutable filter state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      transactionFilterControllerProvider.notifier,
    );

    controller
      ..setSearchText('salary')
      ..toggleTransactionType(TransactionType.income)
      ..setAccountId('account-1')
      ..setDateRange(
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      );

    final filter = container.read(transactionFilterControllerProvider);

    expect(filter.searchText, 'salary');
    expect(filter.transactionTypes, {TransactionType.income});
    expect(filter.accountId, 'account-1');
    expect(filter.startDate, DateTime(2026, 7, 1));
    expect(filter.endDate, DateTime(2026, 7, 31));

    controller.reset();

    expect(
      container.read(transactionFilterControllerProvider).hasFilters,
      isFalse,
    );
  });

  test('account and credit card filters remain mutually exclusive', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(
      transactionFilterControllerProvider.notifier,
    );

    controller.setCreditCardId('credit-card-1');
    controller.setAccountId('account-1');

    final filter = container.read(transactionFilterControllerProvider);

    expect(filter.accountId, 'account-1');
    expect(filter.creditCardId, isNull);
  });
}
