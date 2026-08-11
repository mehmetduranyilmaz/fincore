import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_transfer_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/create_transfer_controller.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a transfer and refreshes the transaction list', () async {
    final repository = _TransactionRepository();
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repository),
        accountRepositoryProvider.overrideWithValue(const _AccountRepository()),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(appShellNavigationControllerProvider.notifier)
        .select(AppShellDestination.transactions);

    await container
        .read(createTransferControllerProvider.notifier)
        .create(_input());

    final createState = container.read(createTransferControllerProvider);
    final transactionsState = container.read(transactionsControllerProvider);

    expect(createState.status, CreateTransferStatus.success);
    expect(transactionsState.status, TransactionsStatus.loaded);
    expect(transactionsState.transactions, hasLength(2));
    expect(transactionsState.transactions.first.amount, -250);
    expect(transactionsState.transactions.last.amount, 250);
  });

  test('exposes failure when batch persistence fails', () async {
    final repository = _TransactionRepository(shouldFail: true);
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repository),
        accountRepositoryProvider.overrideWithValue(const _AccountRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(createTransferControllerProvider.notifier)
        .create(_input());

    final state = container.read(createTransferControllerProvider);

    expect(state.status, CreateTransferStatus.failure);
    expect(state.errorMessage, isNotEmpty);
  });
}

CreateTransferInput _input() {
  return CreateTransferInput(
    fromAccountId: 'account-1',
    toAccountId: 'account-2',
    amount: 250,
    description: 'Test transfer',
    transferDate: DateTime(2020),
  );
}

final class _TransactionRepository implements TransactionRepository {
  _TransactionRepository({this.shouldFail = false});

  final bool shouldFail;
  final List<Transaction> transactions = [];

  @override
  Future<void> create(Transaction transaction) async {
    transactions.insert(0, transaction);
  }

  @override
  Future<void> createMany(List<Transaction> transactions) async {
    if (shouldFail) {
      throw Exception('Create failed');
    }
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

final class _AccountRepository implements AccountRepository {
  const _AccountRepository();

  @override
  Future<List<Account>> getAccounts() async {
    return const [
      Account(
        id: 'account-1',
        name: 'Source',
        type: AccountType.checking,
        currencyCode: 'TRY',
        isArchived: false,
      ),
      Account(
        id: 'account-2',
        name: 'Destination',
        type: AccountType.savings,
        currencyCode: 'TRY',
        isArchived: false,
      ),
    ];
  }
}
