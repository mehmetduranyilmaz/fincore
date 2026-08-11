import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/entities/update_transaction_input.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/edit_transaction_controller.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:fincore_app/features/transactions/presentation/providers/transaction_details_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updates, reloads the list, and refreshes visible details', () async {
    final repository = _TransactionRepository([_transaction()]);
    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container
        .read(appShellNavigationControllerProvider.notifier)
        .select(AppShellDestination.transactions);
    final details = transactionDetailsProvider('transaction-1');
    final subscription = container.listen(details, (previous, next) {});
    addTearDown(subscription.close);
    await container.read(details.future);

    await container
        .read(editTransactionControllerProvider.notifier)
        .update(_input());
    final refreshed = await container.read(details.future);

    expect(
      container.read(editTransactionControllerProvider).status,
      EditTransactionStatus.success,
    );
    expect(
      container.read(transactionsControllerProvider).status,
      TransactionsStatus.loaded,
    );
    expect(refreshed?.amount, 500);
    expect(repository.detailsCallCount, greaterThanOrEqualTo(2));
  });

  test('exposes failure when update persistence fails', () async {
    final repository = _TransactionRepository([
      _transaction(),
    ], shouldFail: true);
    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(editTransactionControllerProvider.notifier)
        .update(_input());

    final state = container.read(editTransactionControllerProvider);

    expect(state.status, EditTransactionStatus.failure);
    expect(state.errorMessage, isNotEmpty);
  });
}

UpdateTransactionInput _input() {
  return UpdateTransactionInput(
    transactionId: 'transaction-1',
    accountId: 'account-1',
    creditCardId: null,
    amount: 500,
    description: 'Updated',
    categoryId: null,
    transactionDate: DateTime(2020),
  );
}

Transaction _transaction() {
  return Transaction(
    id: 'transaction-1',
    accountId: 'account-1',
    creditCardId: null,
    amount: 100,
    transactionType: TransactionType.expense,
    categoryId: null,
    merchant: 'Gider',
    note: null,
    transactionDate: DateTime(2020),
    source: TransactionSource.manual,
    isDeleted: false,
  );
}

final class _TransactionRepository implements TransactionRepository {
  _TransactionRepository(
    List<Transaction> transactions, {
    this.shouldFail = false,
  }) : transactions = [...transactions];

  final bool shouldFail;
  final List<Transaction> transactions;
  int detailsCallCount = 0;

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<Transaction?> getById(String transactionId) async {
    detailsCallCount++;
    for (final transaction in transactions) {
      if (transaction.id == transactionId) {
        return transaction;
      }
    }
    return null;
  }

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return List.unmodifiable(transactions);
  }

  @override
  Future<void> update(Transaction transaction) async {
    if (shouldFail) {
      throw Exception('Update failed');
    }
    final index = transactions.indexWhere(
      (current) => current.id == transaction.id,
    );
    transactions[index] = transaction;
  }
}
