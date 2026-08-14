import 'package:fincore_app/features/budgets/data/datasources/budget_mock_data_source.dart';
import 'package:fincore_app/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:fincore_app/features/budgets/domain/entities/budget.dart';
import 'package:fincore_app/features/budgets/domain/usecases/calculate_budget_progress.dart';
import 'package:fincore_app/features/budgets/domain/usecases/create_budget.dart';
import 'package:fincore_app/features/budgets/domain/usecases/delete_budget.dart';
import 'package:fincore_app/features/budgets/domain/usecases/update_budget.dart';
import 'package:fincore_app/features/categories/data/datasources/category_mock_data_source.dart';
import 'package:fincore_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:fincore_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BudgetRepositoryImpl budgetRepository;
  late CategoryRepositoryImpl categoryRepository;
  late CreateBudgetUseCase createBudget;

  setUp(() {
    budgetRepository = BudgetRepositoryImpl(
      BudgetMockDataSource(seed: const []),
    );
    categoryRepository = CategoryRepositoryImpl(
      CategoryMockDataSource(seed: _categories),
    );
    createBudget = CreateBudgetUseCase(
      budgetRepository,
      categoryRepository,
      clock: () => DateTime(2026, 7, 1),
      idGenerator: () => 'budget-created',
    );
  });

  test('creates a valid monthly expense budget', () async {
    final budget = await createBudget.execute(_createInput());

    expect(budget.id, 'budget-created');
    expect(budget.amount, 8000);
    expect(await budgetRepository.getAll(), [budget]);
  });

  test('rejects duplicate active budgets for the same period', () async {
    await createBudget.execute(_createInput());

    await expectLater(
      createBudget.execute(_createInput()),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects income and deleted categories', () async {
    await expectLater(
      createBudget.execute(_createInput(categoryId: 'income')),
      throwsA(isA<ArgumentError>()),
    );

    await categoryRepository.delete('expense');
    await expectLater(
      createBudget.execute(_createInput()),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects non-positive budget amounts', () async {
    await expectLater(
      createBudget.execute(_createInput(amount: 0)),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('updates a budget while preserving creation metadata', () async {
    final original = await createBudget.execute(_createInput());
    final useCase = UpdateBudgetUseCase(
      budgetRepository,
      categoryRepository,
      clock: () => DateTime(2026, 7, 2),
    );

    final updated = await useCase.execute(
      const UpdateBudgetInput(
        id: 'budget-created',
        categoryId: 'expense',
        month: 8,
        year: 2026,
        amount: 9000,
      ),
    );

    expect(updated.createdAt, original.createdAt);
    expect(updated.updatedAt, DateTime(2026, 7, 2));
    expect(updated.month, 8);
    expect(updated.amount, 9000);
    expect(await budgetRepository.getById(updated.id), updated);
  });

  test('soft deletes a budget and ignores it in active queries', () async {
    await createBudget.execute(_createInput());

    await DeleteBudgetUseCase(budgetRepository).execute('budget-created');

    expect(await budgetRepository.getAll(), isEmpty);
    expect(await budgetRepository.getById('budget-created'), isNull);
    expect(
      await budgetRepository.exists(
        categoryId: 'expense',
        month: 7,
        year: 2026,
      ),
      isFalse,
    );
  });

  test('calculates progress from matching expense transactions only', () async {
    final budget = Budget(
      id: 'budget',
      categoryId: 'expense',
      month: 7,
      year: 2026,
      amount: 8000,
      createdAt: _date,
      updatedAt: _date,
      isDeleted: false,
    );
    final transactionRepository = TransactionRepositoryImpl(
      TransactionMockDataSource(
        initialTransactions: [
          _transaction('counted', 5250, TransactionType.expense),
          _openAccountExpense('open-account-training', 250),
          _transaction(
            'customer-card-payment',
            750,
            TransactionType.expense,
            customerId: 'customer-1',
            customerBalanceDelta: 750,
            paymentGroupId: 'customer-payment-group',
          ),
          _transaction('income', 1000, TransactionType.income),
          _transaction('transfer', -500, TransactionType.transfer),
          _transaction(
            'deleted',
            2000,
            TransactionType.expense,
            isDeleted: true,
          ),
          _transaction(
            'other-category',
            2000,
            TransactionType.expense,
            categoryId: 'other',
          ),
          _transaction(
            'other-month',
            2000,
            TransactionType.expense,
            date: DateTime(2026, 6, 30),
          ),
        ],
      ),
    );

    final progress = await CalculateBudgetProgressUseCase(
      transactionRepository,
    ).execute(budget);

    expect(progress.budgetAmount, 8000);
    expect(progress.spentAmount, 5500);
    expect(progress.remainingAmount, 2500);
    expect(progress.progress, closeTo(0.6875, 0.00001));
  });
}

final DateTime _date = DateTime(2026, 7, 1);

const List<Category> _categories = [
  Category(
    id: 'expense',
    name: 'Groceries',
    icon: 'shopping_cart',
    color: 0xFF2E7D32,
    type: CategoryType.expense,
  ),
  Category(
    id: 'income',
    name: 'Salary',
    icon: 'payments',
    color: 0xFF1565C0,
    type: CategoryType.income,
  ),
];

CreateBudgetInput _createInput({
  String categoryId = 'expense',
  double amount = 8000,
}) {
  return CreateBudgetInput(
    categoryId: categoryId,
    month: 7,
    year: 2026,
    amount: amount,
  );
}

Transaction _transaction(
  String id,
  double amount,
  TransactionType type, {
  String categoryId = 'expense',
  DateTime? date,
  bool isDeleted = false,
  String? customerId,
  double? customerBalanceDelta,
  String? paymentGroupId,
}) {
  return Transaction(
    id: id,
    accountId: 'account-1',
    creditCardId: null,
    amount: amount,
    transactionType: type,
    categoryId: categoryId,
    merchant: id,
    note: null,
    transactionDate: date ?? _date,
    source: TransactionSource.manual,
    isDeleted: isDeleted,
    transferGroupId: type == TransactionType.transfer ? 'transfer' : null,
    customerId: customerId,
    customerBalanceDelta: customerBalanceDelta,
    paymentGroupId: paymentGroupId,
  );
}

Transaction _openAccountExpense(String id, double amount) {
  return Transaction(
    id: id,
    accountId: null,
    creditCardId: null,
    amount: amount,
    transactionType: TransactionType.expense,
    categoryId: 'expense',
    merchant: id,
    note: null,
    transactionDate: _date,
    source: TransactionSource.manual,
    isDeleted: false,
    customerId: 'customer-1',
    customerBalanceDelta: -amount,
  );
}
