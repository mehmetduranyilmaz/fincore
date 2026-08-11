import 'package:fincore_app/features/transactions/domain/entities/create_receipt_expense_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/installment_transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/convert_expense_to_installments.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_receipt_expense.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates receipt installments starting on the purchase date', () async {
    final repository = _InstallmentRepository();
    final useCase = CreateReceiptExpenseUseCase(
      repository,
      clock: () => DateTime(2026, 8, 20),
      planIdGenerator: () => 'plan-1',
      transactionIdGenerator: (index) => 'receipt-$index',
    );

    final result = await useCase.execute(
      CreateReceiptExpenseInput(
        accountId: null,
        creditCardId: 'card-1',
        totalAmount: 100,
        installmentAmounts: const [33.33, 33.33, 33.34],
        description: 'Test Market',
        categoryId: 'category-grocery',
        transactionDate: DateTime(2026, 8, 10),
      ),
    );

    expect(result.map((item) => item.amount), [33.33, 33.33, 33.34]);
    expect(result.map((item) => item.transactionDate), [
      DateTime(2026, 8, 10),
      DateTime(2026, 9, 10),
      DateTime(2026, 10, 10),
    ]);
    expect(result.map((item) => item.installmentNumber), [1, 2, 3]);
    expect(result.every((item) => item.installmentPlanId == 'plan-1'), isTrue);
    expect(
      result.every((item) => item.source == TransactionSource.receiptScan),
      isTrue,
    );
    expect(repository.createdPlan, result);
  });

  test('rejects a scanned receipt paid from an account', () async {
    final repository = _InstallmentRepository();
    final useCase = CreateReceiptExpenseUseCase(
      repository,
      clock: () => DateTime(2026, 8, 8),
    );

    await expectLater(
      () => useCase.execute(
        CreateReceiptExpenseInput(
          accountId: 'account-1',
          creditCardId: null,
          totalAmount: 100,
          installmentAmounts: const [100],
          description: 'Test Market',
          categoryId: null,
          transactionDate: DateTime(2026, 8, 8),
        ),
      ),
      throwsArgumentError,
    );
    expect(repository.createdPlan, isNull);
  });

  test('converts a single expense while preserving its original id', () async {
    final original = Transaction(
      id: 'transaction-1',
      accountId: null,
      creditCardId: 'card-1',
      amount: 100,
      transactionType: TransactionType.expense,
      categoryId: 'category-grocery',
      merchant: 'Test Market',
      note: null,
      transactionDate: DateTime(2026, 8, 10),
      source: TransactionSource.manual,
      isDeleted: false,
    );
    final installmentRepository = _InstallmentRepository();
    final useCase = ConvertExpenseToInstallmentsUseCase(
      _TransactionRepository(original),
      installmentRepository,
      planIdGenerator: () => 'plan-converted',
      transactionIdGenerator: (index) => 'new-$index',
    );

    final result = await useCase.execute(
      const ConvertExpenseToInstallmentsInput(
        transactionId: 'transaction-1',
        installmentAmounts: [25, 25, 50],
      ),
    );

    expect(result.first.id, original.id);
    expect(result.first.amount, 25);
    expect(result.skip(1).map((item) => item.id), ['new-1', 'new-2']);
    expect(result.map((item) => item.transactionDate), [
      DateTime(2026, 8, 10),
      DateTime(2026, 9, 10),
      DateTime(2026, 10, 10),
    ]);
    expect(result.every((item) => item.installmentTotalAmount == 100), isTrue);
    expect(installmentRepository.replacedPlan, result);
  });
}

final class _InstallmentRepository implements InstallmentTransactionRepository {
  List<Transaction>? createdPlan;
  List<Transaction>? replacedPlan;

  @override
  Future<void> createPlan(List<Transaction> installments) async {
    createdPlan = installments;
  }

  @override
  Future<void> replaceWithPlan(List<Transaction> installments) async {
    replacedPlan = installments;
  }
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.transaction);

  final Transaction transaction;

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<Transaction?> getById(String transactionId) async {
    return transaction.id == transactionId ? transaction : null;
  }

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return [transaction];
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
