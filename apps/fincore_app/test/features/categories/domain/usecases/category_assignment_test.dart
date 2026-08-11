import 'package:fincore_app/features/categories/data/datasources/category_mock_data_source.dart';
import 'package:fincore_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:fincore_app/features/categories/data/services/category_assignment_validator.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_manual_expense_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_manual_income_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_manual_expense.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_manual_income.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const incomeCategory = Category(
    id: 'income',
    name: 'Salary',
    icon: 'payments',
    color: 0xFF1565C0,
    type: CategoryType.income,
  );

  test('rejects assigning a deleted category to a new transaction', () async {
    final categoryRepository = CategoryRepositoryImpl(
      CategoryMockDataSource(seed: const [incomeCategory]),
    );
    await categoryRepository.delete(incomeCategory.id);
    final useCase = CreateManualIncomeUseCase(
      _TransactionRepository(),
      categoryValidator: CategoryAssignmentValidator(categoryRepository),
      clock: () => DateTime(2026, 7, 25),
    );

    await expectLater(
      useCase.execute(
        CreateManualIncomeInput(
          accountId: 'account-1',
          amount: 100,
          description: 'Salary',
          categoryId: incomeCategory.id,
          transactionDate: DateTime(2026, 7, 25),
        ),
      ),
      throwsStateError,
    );
  });

  test('rejects assigning an income category to an expense', () async {
    final categoryRepository = CategoryRepositoryImpl(
      CategoryMockDataSource(seed: const [incomeCategory]),
    );
    final useCase = CreateManualExpenseUseCase(
      _TransactionRepository(),
      categoryValidator: CategoryAssignmentValidator(categoryRepository),
      clock: () => DateTime(2026, 7, 25),
    );

    await expectLater(
      useCase.execute(
        CreateManualExpenseInput(
          accountId: 'account-1',
          creditCardId: null,
          amount: 100,
          description: 'Gider',
          categoryId: incomeCategory.id,
          transactionDate: DateTime(2026, 7, 25),
        ),
      ),
      throwsStateError,
    );
  });
}

final class _TransactionRepository implements TransactionRepository {
  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return const [];
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
