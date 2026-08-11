import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_manual_expense_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/create_expense_controller.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates an expense and refreshes the transaction list', () async {
    final repository = _TransactionRepository();
    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container
        .read(appShellNavigationControllerProvider.notifier)
        .select(AppShellDestination.transactions);

    await container
        .read(createExpenseControllerProvider.notifier)
        .create(_input());

    final createState = container.read(createExpenseControllerProvider);
    final transactionsState = container.read(transactionsControllerProvider);

    expect(createState.status, CreateExpenseStatus.success);
    expect(transactionsState.status, TransactionsStatus.loaded);
    expect(transactionsState.transactions, hasLength(1));
    expect(transactionsState.transactions.single.merchant, 'Test Expense');
  });

  test('exposes failure when persistence fails', () async {
    final repository = _TransactionRepository(shouldFail: true);
    final container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(createExpenseControllerProvider.notifier)
        .create(_input());

    final state = container.read(createExpenseControllerProvider);

    expect(state.status, CreateExpenseStatus.failure);
    expect(state.errorMessage, isNotEmpty);
  });

  test(
    'does not load the transaction list while another page is active',
    () async {
      final repository = _TransactionRepository();
      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(createExpenseControllerProvider.notifier)
          .create(_input());

      expect(
        container.read(transactionsControllerProvider).status,
        TransactionsStatus.initial,
      );
      expect(repository.transactions, hasLength(1));
    },
  );
}

CreateManualExpenseInput _input() {
  return CreateManualExpenseInput(
    accountId: 'account-1',
    creditCardId: null,
    amount: 250,
    description: 'Test Expense',
    categoryId: null,
    transactionDate: DateTime(2020),
  );
}

final class _TransactionRepository implements TransactionRepository {
  _TransactionRepository({this.shouldFail = false});

  final bool shouldFail;
  final List<Transaction> transactions = [];

  @override
  Future<void> create(Transaction transaction) async {
    if (shouldFail) {
      throw Exception('Create failed');
    }
    transactions.insert(0, transaction);
  }

  @override
  Future<void> createMany(List<Transaction> transactions) async {
    this.transactions.insertAll(0, transactions);
  }

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return List.unmodifiable(transactions);
  }

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<void> update(Transaction transaction) async {}
}
