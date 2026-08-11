import 'dart:async';

import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transaction_filter_controller.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../transactions_test_data.dart';

void main() {
  test('moves from initial to loading and loaded', () async {
    final completer = Completer<List<Transaction>>();
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(
          _TransactionRepository(completer.future),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(transactionsControllerProvider).status,
      TransactionsStatus.initial,
    );

    final load = container.read(transactionsControllerProvider.notifier).load();

    expect(
      container.read(transactionsControllerProvider).status,
      TransactionsStatus.loading,
    );

    final transactions = createTransactions();
    completer.complete(transactions);
    await load;

    final state = container.read(transactionsControllerProvider);

    expect(state.status, TransactionsStatus.loaded);
    expect(state.transactions, transactions);
    expect(
      () => state.transactions.add(transactions.first),
      throwsUnsupportedError,
    );
    expect(state.errorMessage, isNull);
  });

  test('moves to failure when the repository throws', () async {
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(
          _TransactionRepository(Future.error(Exception('Failed'))),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(transactionsControllerProvider.notifier).load();

    final state = container.read(transactionsControllerProvider);

    expect(state.status, TransactionsStatus.failure);
    expect(state.transactions, isEmpty);
    expect(state.errorMessage, isNotEmpty);
  });

  test('reloads transactions whenever the filter changes', () async {
    final repository = _FilteringTransactionRepository(createTransactions());
    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(transactionsControllerProvider.notifier).load();
    container
        .read(transactionFilterControllerProvider.notifier)
        .toggleTransactionType(TransactionType.income);
    await pumpEventQueue();

    final state = container.read(transactionsControllerProvider);

    expect(repository.filters, hasLength(2));
    expect(repository.filters.last.transactionTypes, {TransactionType.income});
    expect(state.status, TransactionsStatus.loaded);
    expect(state.transactions, hasLength(1));
    expect(state.transactions.single.transactionType, TransactionType.income);
  });
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.result);

  final Future<List<Transaction>> result;

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) => result;

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<void> update(Transaction transaction) async {}
}

final class _FilteringTransactionRepository implements TransactionRepository {
  _FilteringTransactionRepository(this.transactions);

  final List<Transaction> transactions;
  final List<TransactionFilter> filters = [];

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    filters.add(filter);
    if (filter.transactionTypes.isEmpty) {
      return transactions;
    }
    return transactions
        .where(
          (transaction) =>
              filter.transactionTypes.contains(transaction.transactionType),
        )
        .toList(growable: false);
  }

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<void> update(Transaction transaction) async {}
}
