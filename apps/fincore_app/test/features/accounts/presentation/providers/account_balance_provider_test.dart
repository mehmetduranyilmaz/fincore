import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/presentation/providers/account_balance_provider.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshes when a related transaction changes', () async {
    final repository = _TransactionRepository([
      _transaction(id: 'income', amount: 100, type: TransactionType.income),
    ]);
    final container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repository),
        accountRepositoryProvider.overrideWithValue(const _AccountRepository()),
      ],
    );
    addTearDown(container.dispose);
    final provider = accountBalanceProvider('account-1');
    final unrelatedProvider = accountBalanceProvider('account-2');
    final subscription = container.listen(provider, (previous, next) {});
    final unrelatedSubscription = container.listen(
      unrelatedProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);
    addTearDown(unrelatedSubscription.close);

    expect((await container.read(provider.future)).currentBalance, 100);
    expect((await container.read(unrelatedProvider.future)).currentBalance, 0);

    final expense = _transaction(
      id: 'expense',
      amount: 40,
      type: TransactionType.expense,
    );
    await repository.create(expense);
    await container
        .read(appDataRefreshCoordinatorProvider)
        .transactionsChanged(current: [expense]);

    expect((await container.read(provider.future)).currentBalance, 60);
    expect(repository.queryCount, 3);
  });
}

final class _AccountRepository implements AccountRepository {
  const _AccountRepository();

  @override
  Future<List<Account>> getAccounts() async => const [
    Account(
      id: 'account-1',
      name: 'Test',
      type: AccountType.checking,
      currencyCode: 'TRY',
      isArchived: false,
    ),
    Account(
      id: 'account-2',
      name: 'Unrelated',
      type: AccountType.checking,
      currencyCode: 'TRY',
      isArchived: false,
    ),
  ];
}

Transaction _transaction({
  required String id,
  required double amount,
  required TransactionType type,
}) {
  return Transaction(
    id: id,
    accountId: 'account-1',
    creditCardId: null,
    amount: amount,
    transactionType: type,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: DateTime(2026, 7, 25),
    source: TransactionSource.manual,
    isDeleted: false,
  );
}

final class _TransactionRepository implements TransactionRepository {
  _TransactionRepository(List<Transaction> transactions)
    : transactions = [...transactions];

  final List<Transaction> transactions;
  int queryCount = 0;

  @override
  Future<void> create(Transaction transaction) async {
    transactions.insert(0, transaction);
  }

  @override
  Future<void> createMany(List<Transaction> transactions) async {
    this.transactions.insertAll(0, transactions);
  }

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    queryCount++;
    return transactions
        .where(
          (transaction) =>
              filter.accountId == null ||
              transaction.accountId == filter.accountId,
        )
        .toList(growable: false);
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
