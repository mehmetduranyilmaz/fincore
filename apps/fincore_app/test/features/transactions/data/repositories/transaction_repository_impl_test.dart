import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:fincore_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../transactions_test_data.dart';

void main() {
  test('returns an immutable transaction list from the data source', () async {
    final transactions = createTransactions();
    final dataSource = _TransactionDataSource(transactions);
    final repository = TransactionRepositoryImpl(dataSource);

    final result = await repository.getTransactions(TransactionFilter());

    expect(result, transactions);
    expect(dataSource.callCount, 1);
    expect(() => result.add(transactions.first), throwsUnsupportedError);
  });

  test('mock data starts without sample transactions', () async {
    final transactions = await TransactionMockDataSource().getTransactions(
      TransactionFilter(),
    );

    expect(transactions, isEmpty);
  });

  test('persists a created transaction in memory', () async {
    final dataSource = TransactionMockDataSource(initialTransactions: []);
    final repository = TransactionRepositoryImpl(dataSource);
    final transaction = createTransactions().first;

    await repository.create(transaction);

    expect(await repository.getTransactions(TransactionFilter()), [
      transaction,
    ]);
  });

  test(
    'credit card usage lookup ignores legacy soft-deleted movements',
    () async {
      final current = createTransactions().firstWhere(
        (item) => item.creditCardId != null,
      );
      final movement = Transaction(
        id: current.id,
        accountId: current.accountId,
        creditCardId: current.creditCardId,
        amount: current.amount,
        transactionType: current.transactionType,
        categoryId: current.categoryId,
        merchant: current.merchant,
        note: current.note,
        transactionDate: current.transactionDate,
        source: current.source,
        isDeleted: true,
      );
      final dataSource = TransactionMockDataSource(
        initialTransactions: [movement],
      );

      expect(
        await dataSource.hasAnyCreditCardMovement(movement.creditCardId!),
        isFalse,
      );
      expect(await dataSource.getTransactions(TransactionFilter()), isEmpty);
    },
  );

  test(
    'reference usage lookups ignore legacy soft-deleted movements',
    () async {
      final movement = Transaction(
        id: 'deleted-customer-expense',
        accountId: 'account-used',
        creditCardId: null,
        amount: 100,
        transactionType: TransactionType.expense,
        categoryId: 'category-used',
        merchant: 'Geçmiş hareket',
        note: null,
        transactionDate: DateTime(2026, 8, 1),
        source: createTransactions().first.source,
        isDeleted: true,
        customerId: 'customer-used',
        customerBalanceDelta: 100,
      );
      final dataSource = TransactionMockDataSource(
        initialTransactions: [movement],
      );

      expect(await dataSource.hasAnyAccountMovement('account-used'), isFalse);
      expect(await dataSource.hasAnyCategoryMovement('category-used'), isFalse);
      expect(await dataSource.hasAnyCustomerMovement('customer-used'), isFalse);
    },
  );

  test('hard deletion releases every referenced master card', () async {
    final accountMovement = Transaction(
      id: 'account-movement',
      accountId: 'account-used',
      creditCardId: null,
      amount: 100,
      transactionType: TransactionType.expense,
      categoryId: 'category-used',
      merchant: 'Account expense',
      note: null,
      transactionDate: DateTime(2026, 8, 1),
      source: createTransactions().first.source,
      isDeleted: false,
      customerId: 'customer-used',
      customerBalanceDelta: 100,
    );
    final cardMovement = Transaction(
      id: 'credit-card-movement',
      accountId: null,
      creditCardId: 'credit-card-used',
      amount: 200,
      transactionType: TransactionType.expense,
      categoryId: 'category-used',
      merchant: 'Credit card expense',
      note: null,
      transactionDate: DateTime(2026, 8, 2),
      source: createTransactions().first.source,
      isDeleted: false,
    );
    final dataSource = TransactionMockDataSource(
      initialTransactions: [accountMovement, cardMovement],
    );

    expect(await dataSource.hasAnyAccountMovement('account-used'), isTrue);
    expect(
      await dataSource.hasAnyCreditCardMovement('credit-card-used'),
      isTrue,
    );
    expect(await dataSource.hasAnyCategoryMovement('category-used'), isTrue);
    expect(await dataSource.hasAnyCustomerMovement('customer-used'), isTrue);

    await dataSource.removeMany({accountMovement.id, cardMovement.id});

    expect(await dataSource.hasAnyAccountMovement('account-used'), isFalse);
    expect(
      await dataSource.hasAnyCreditCardMovement('credit-card-used'),
      isFalse,
    );
    expect(await dataSource.hasAnyCategoryMovement('category-used'), isFalse);
    expect(await dataSource.hasAnyCustomerMovement('customer-used'), isFalse);
    expect(await dataSource.findById(accountMovement.id), isNull);
    expect(await dataSource.findById(cardMovement.id), isNull);
  });

  test('persists a transaction batch in insertion order', () async {
    final existing = createTransactions().first;
    final transactions = createTransactions().skip(1).take(2).toList();
    final dataSource = TransactionMockDataSource(
      initialTransactions: [existing],
    );
    final repository = TransactionRepositoryImpl(dataSource);

    await repository.createMany(transactions);

    expect(await repository.getTransactions(TransactionFilter()), [
      ...transactions,
      existing,
    ]);
  });

  test('applies type, source, date, and search filters in memory', () async {
    final repository = TransactionRepositoryImpl(
      TransactionMockDataSource(initialTransactions: createTransactions()),
    );

    final expenseResult = await repository.getTransactions(
      TransactionFilter(transactionTypes: {TransactionType.expense}),
    );
    final accountResult = await repository.getTransactions(
      TransactionFilter(accountId: 'account-1'),
    );
    final creditCardResult = await repository.getTransactions(
      TransactionFilter(creditCardId: 'credit-card-1'),
    );
    final dateResult = await repository.getTransactions(
      TransactionFilter(
        startDate: DateTime(2026, 7, 24),
        endDate: DateTime(2026, 7, 24),
      ),
    );
    final searchResult = await repository.getTransactions(
      TransactionFilter(searchText: 'NOTE'),
    );

    expect(expenseResult.map((transaction) => transaction.id), [
      'transaction-1',
    ]);
    expect(accountResult.map((transaction) => transaction.id), [
      'transaction-1',
    ]);
    expect(creditCardResult.map((transaction) => transaction.id), [
      'transaction-2',
    ]);
    expect(dateResult.map((transaction) => transaction.id), ['transaction-2']);
    expect(searchResult.map((transaction) => transaction.id), [
      'transaction-2',
    ]);
  });

  test('looks up and updates a transaction without changing order', () async {
    final transactions = createTransactions();
    final repository = TransactionRepositoryImpl(
      TransactionMockDataSource(initialTransactions: transactions),
    );
    final current = (await repository.getById('transaction-2'))!;
    final updated = Transaction(
      id: current.id,
      accountId: current.accountId,
      creditCardId: current.creditCardId,
      amount: 7500,
      transactionType: current.transactionType,
      categoryId: current.categoryId,
      merchant: 'Updated Income',
      note: current.note,
      transactionDate: current.transactionDate,
      source: current.source,
      isDeleted: current.isDeleted,
    );

    await repository.update(updated);
    final result = await repository.getTransactions(TransactionFilter());

    expect(result.map((transaction) => transaction.id), [
      'transaction-1',
      'transaction-2',
    ]);
    expect(result.last, updated);
    expect(await repository.getById('missing'), isNull);
  });
}

final class _TransactionDataSource implements TransactionDataSource {
  _TransactionDataSource(this.transactions);

  final List<Transaction> transactions;
  int callCount = 0;

  @override
  Future<bool> hasAnyCreditCardMovement(String creditCardId) async {
    return transactions.any((item) => item.creditCardId == creditCardId);
  }

  @override
  Future<bool> hasAnyAccountMovement(String accountId) async {
    return transactions.any((item) => item.accountId == accountId);
  }

  @override
  Future<bool> hasAnyCategoryMovement(String categoryId) async {
    return transactions.any((item) => item.categoryId == categoryId);
  }

  @override
  Future<bool> hasAnyCustomerMovement(String customerId) async {
    return transactions.any((item) => item.customerId == customerId);
  }

  @override
  Future<Transaction?> findById(String transactionId) async {
    for (final transaction in transactions) {
      if (transaction.id == transactionId) {
        return transaction;
      }
    }
    return null;
  }

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    callCount++;
    return transactions;
  }

  @override
  Future<void> insert(Transaction transaction) async {
    transactions.insert(0, transaction);
  }

  @override
  Future<void> insertMany(List<Transaction> transactions) async {
    this.transactions.insertAll(0, transactions);
  }

  @override
  Future<void> replace(Transaction transaction) async {
    final index = transactions.indexWhere(
      (current) => current.id == transaction.id,
    );
    transactions[index] = transaction;
  }

  @override
  Future<void> removeMany(Set<String> transactionIds) async {
    transactions.removeWhere((item) => transactionIds.contains(item.id));
  }
}
