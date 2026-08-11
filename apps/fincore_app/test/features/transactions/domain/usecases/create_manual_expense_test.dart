import 'package:fincore_app/features/transactions/domain/entities/create_manual_expense_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/installment_transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_manual_expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _TransactionRepository repository;
  late CreateManualExpenseUseCase useCase;

  setUp(() {
    repository = _TransactionRepository();
    useCase = CreateManualExpenseUseCase(
      repository,
      installmentRepository: repository,
      clock: () => DateTime(2026, 7, 25, 12),
      idGenerator: () => 'manual-expense-1',
    );
  });

  test('creates and persists a manual expense', () async {
    final transaction = await useCase.execute(
      CreateManualExpenseInput(
        accountId: 'account-1',
        creditCardId: null,
        amount: 125.50,
        description: '  Market  ',
        categoryId: 'category-market',
        transactionDate: DateTime(2026, 7, 25),
      ),
    );

    expect(transaction.id, 'manual-expense-1');
    expect(transaction.transactionType, TransactionType.expense);
    expect(transaction.source, TransactionSource.manual);
    expect(transaction.merchant, 'Market');
    expect(transaction.isDeleted, isFalse);
    expect(repository.transactions, [transaction]);
  });

  test('rejects a non-positive amount', () {
    expect(
      () => useCase.execute(
        CreateManualExpenseInput(
          accountId: 'account-1',
          creditCardId: null,
          amount: 0,
          description: 'Market',
          categoryId: null,
          transactionDate: DateTime(2026, 7, 25),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects invalid source combinations', () {
    expect(
      () => useCase.execute(
        CreateManualExpenseInput(
          accountId: null,
          creditCardId: null,
          amount: 100,
          description: 'Market',
          categoryId: null,
          transactionDate: DateTime(2026, 7, 25),
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => useCase.execute(
        CreateManualExpenseInput(
          accountId: 'account-1',
          creditCardId: 'credit-card-1',
          amount: 100,
          description: 'Market',
          categoryId: null,
          transactionDate: DateTime(2026, 7, 25),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects a future transaction date', () {
    expect(
      () => useCase.execute(
        CreateManualExpenseInput(
          accountId: 'account-1',
          creditCardId: null,
          amount: 100,
          description: 'Market',
          categoryId: null,
          transactionDate: DateTime(2026, 7, 26),
        ),
      ),
      throwsArgumentError,
    );
  });

  test(
    'creates editable installments whose total equals the expense',
    () async {
      final firstInstallment = await useCase.execute(
        CreateManualExpenseInput(
          accountId: null,
          creditCardId: 'credit-card-1',
          amount: 100,
          description: 'Market',
          categoryId: null,
          transactionDate: DateTime(2026, 7, 25),
          installmentAmounts: const [33.33, 33.33, 33.34],
        ),
      );

      expect(firstInstallment.id, 'manual-expense-1');
      expect(repository.transactions.map((item) => item.amount), [
        33.33,
        33.33,
        33.34,
      ]);
      expect(repository.transactions.map((item) => item.transactionDate), [
        DateTime(2026, 7, 25),
        DateTime(2026, 8, 25),
        DateTime(2026, 9, 25),
      ]);
      expect(repository.transactions.map((item) => item.installmentNumber), [
        1,
        2,
        3,
      ]);
      expect(repository.transactions.map((item) => item.installmentCount), [
        3,
        3,
        3,
      ]);
    },
  );

  test('rejects installments paid from a bank account', () {
    expect(
      () => useCase.execute(
        CreateManualExpenseInput(
          accountId: 'account-1',
          creditCardId: null,
          amount: 100,
          description: 'Market',
          categoryId: null,
          transactionDate: DateTime(2026, 7, 25),
          installmentAmounts: const [50, 50],
        ),
      ),
      throwsArgumentError,
    );
  });
}

final class _TransactionRepository
    implements TransactionRepository, InstallmentTransactionRepository {
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

  @override
  Future<void> createPlan(List<Transaction> installments) async {
    transactions.addAll(installments);
  }

  @override
  Future<void> replaceWithPlan(List<Transaction> installments) async {
    transactions
      ..clear()
      ..addAll(installments);
  }
}
