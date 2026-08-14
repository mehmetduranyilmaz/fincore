import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/dashboard/presentation/providers/dashboard_summary_provider.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshes analytics when a transaction changes', () async {
    final transactionRepository = _TransactionRepository([
      _transaction(
        id: 'income',
        accountId: 'account-1',
        amount: 100,
        type: TransactionType.income,
      ),
      _transaction(
        id: 'card-expense',
        creditCardId: 'credit-card-1',
        amount: 20,
        type: TransactionType.expense,
      ),
    ]);
    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(const _AccountRepository()),
        creditCardRepositoryProvider.overrideWithValue(
          const _CreditCardRepository(),
        ),
        transactionRepositoryProvider.overrideWithValue(transactionRepository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      dashboardSummaryProvider,
      (previous, next) {},
    );
    addTearDown(subscription.close);

    expect(
      (await container.read(dashboardSummaryProvider.future)).netWorth,
      80,
    );

    final expense = _transaction(
      id: 'expense',
      customerId: 'customer-1',
      customerBalanceDelta: -10,
      amount: 10,
      type: TransactionType.expense,
    );
    await transactionRepository.create(expense);
    await container
        .read(appDataRefreshCoordinatorProvider)
        .transactionsChanged(current: [expense]);
    final refreshed = await container.read(dashboardSummaryProvider.future);

    expect(refreshed.totalAccountBalances, 100);
    expect(refreshed.monthlyExpense, 30);
    expect(refreshed.netWorth, 80);
  });
}

Transaction _transaction({
  required String id,
  String? accountId,
  String? creditCardId,
  String? customerId,
  double? customerBalanceDelta,
  required double amount,
  required TransactionType type,
}) {
  return Transaction(
    id: id,
    accountId: accountId,
    creditCardId: creditCardId,
    customerId: customerId,
    customerBalanceDelta: customerBalanceDelta,
    amount: amount,
    transactionType: type,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: DateTime.now(),
    source: TransactionSource.manual,
    isDeleted: false,
  );
}

final class _AccountRepository implements AccountRepository {
  const _AccountRepository();

  @override
  Future<List<Account>> getAccounts() async {
    return const [
      Account(
        id: 'account-1',
        name: 'Primary',
        type: AccountType.checking,
        currencyCode: 'TRY',
        isArchived: false,
      ),
    ];
  }
}

final class _CreditCardRepository implements CreditCardRepository {
  const _CreditCardRepository();

  @override
  Future<List<CreditCard>> getCreditCards() async {
    return const [
      CreditCard(
        id: 'credit-card-1',
        bankName: 'Bank',
        cardName: 'Card',
        lastFourDigits: '1111',
        creditLimit: 1000,
        statementDay: 10,
        dueDay: 20,
        currencyCode: 'TRY',
        isArchived: false,
      ),
    ];
  }
}

final class _TransactionRepository implements TransactionRepository {
  _TransactionRepository(List<Transaction> transactions)
    : transactions = [...transactions];

  final List<Transaction> transactions;

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
    return transactions
        .where((transaction) {
          return (filter.accountId == null ||
                  transaction.accountId == filter.accountId) &&
              (filter.creditCardId == null ||
                  transaction.creditCardId == filter.creditCardId);
        })
        .toList(growable: false);
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
