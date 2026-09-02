import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_balance_provider.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshes when a related transaction changes', () async {
    final repository = _TransactionRepository([
      _transaction(id: 'expense', amount: 100),
    ]);
    final container = ProviderContainer(
      overrides: [
        creditCardRepositoryProvider.overrideWithValue(
          const _CreditCardRepository(),
        ),
        transactionRepositoryProvider.overrideWithValue(repository),
        creditCardStatementRepositoryProvider.overrideWithValue(
          const _StatementRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final provider = creditCardBalanceProvider('credit-card-1');
    final subscription = container.listen(provider, (previous, next) {});
    addTearDown(subscription.close);

    expect((await container.read(provider.future)).currentDebt, 100);

    final expense = _transaction(id: 'second-expense', amount: 40);
    await repository.create(expense);
    await container
        .read(appDataRefreshCoordinatorProvider)
        .transactionsChanged(current: [expense]);

    expect((await container.read(provider.future)).currentDebt, 140);
    expect(repository.queryCount, 2);
  });
}

final class _StatementRepository implements CreditCardStatementRepository {
  const _StatementRepository();

  @override
  Future<void> create(CreditCardStatement statement) async {}

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async => const [];
}

Transaction _transaction({required String id, required double amount}) {
  return Transaction(
    id: id,
    accountId: null,
    creditCardId: 'credit-card-1',
    amount: amount,
    transactionType: TransactionType.expense,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: DateTime(2026, 7, 25),
    source: TransactionSource.manual,
    isDeleted: false,
  );
}

final class _CreditCardRepository implements CreditCardRepository {
  const _CreditCardRepository();

  @override
  Future<List<CreditCard>> getCreditCards() async {
    return const [
      CreditCard(
        id: 'credit-card-1',
        bankName: 'Test Bank',
        cardName: 'Test Card',
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
              filter.creditCardId == null ||
              transaction.creditCardId == filter.creditCardId,
        )
        .toList(growable: false);
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
