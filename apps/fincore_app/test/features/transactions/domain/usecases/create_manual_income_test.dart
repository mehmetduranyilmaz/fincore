import 'package:fincore_app/features/transactions/domain/entities/create_manual_income_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_manual_income.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _TransactionRepository repository;
  late CreateManualIncomeUseCase useCase;

  setUp(() {
    repository = _TransactionRepository();
    useCase = CreateManualIncomeUseCase(
      repository,
      clock: () => DateTime(2026, 7, 25, 12),
      idGenerator: () => 'manual-income-1',
    );
  });

  test('creates and persists a manual income', () async {
    final transaction = await useCase.execute(_input());

    expect(transaction.id, 'manual-income-1');
    expect(transaction.accountId, 'account-1');
    expect(transaction.creditCardId, isNull);
    expect(transaction.amount, 1000);
    expect(transaction.merchant, 'Salary');
    expect(transaction.categoryId, 'category-salary');
    expect(transaction.transactionType, TransactionType.income);
    expect(transaction.source, TransactionSource.manual);
    expect(transaction.isDeleted, isFalse);
    expect(repository.transactions, [transaction]);
  });

  test('rejects a non-finite or non-positive amount', () {
    for (final amount in <double>[0, -1, double.infinity, double.nan]) {
      expect(
        () => useCase.execute(_input(amount: amount)),
        throwsArgumentError,
      );
    }
  });

  test('rejects a missing account id', () {
    expect(() => useCase.execute(_input(accountId: '  ')), throwsArgumentError);
  });

  test('rejects an empty description', () {
    expect(
      () => useCase.execute(_input(description: '  ')),
      throwsArgumentError,
    );
  });

  test('rejects a future transaction date', () {
    expect(
      () => useCase.execute(_input(transactionDate: DateTime(2026, 7, 25, 13))),
      throwsArgumentError,
    );
  });
}

CreateManualIncomeInput _input({
  String accountId = 'account-1',
  double amount = 1000,
  String description = '  Salary  ',
  DateTime? transactionDate,
}) {
  return CreateManualIncomeInput(
    accountId: accountId,
    amount: amount,
    description: description,
    categoryId: 'category-salary',
    transactionDate: transactionDate ?? DateTime(2026, 7, 25),
  );
}

final class _TransactionRepository implements TransactionRepository {
  final List<Transaction> transactions = [];

  @override
  Future<void> create(Transaction transaction) async {
    transactions.add(transaction);
  }

  @override
  Future<void> createMany(List<Transaction> transactions) async {
    this.transactions.addAll(transactions);
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
