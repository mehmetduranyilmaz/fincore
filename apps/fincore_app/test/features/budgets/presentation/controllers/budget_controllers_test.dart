import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/budgets/data/datasources/budget_mock_data_source.dart';
import 'package:fincore_app/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:fincore_app/features/budgets/domain/entities/budget.dart';
import 'package:fincore_app/features/budgets/domain/usecases/create_budget.dart';
import 'package:fincore_app/features/budgets/domain/usecases/update_budget.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/create_budget_controller.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/delete_budget_controller.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/edit_budget_controller.dart';
import 'package:fincore_app/features/categories/data/datasources/category_mock_data_source.dart';
import 'package:fincore_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:fincore_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create, edit and delete controllers refresh the budget list', () async {
    final resources = _resources();
    final container = resources.container;
    addTearDown(container.dispose);
    container
        .read(appShellNavigationControllerProvider.notifier)
        .select(AppShellDestination.budgets);

    await container.read(budgetsControllerProvider.notifier).load();
    expect(container.read(budgetsControllerProvider).items, isEmpty);

    await container
        .read(createBudgetControllerProvider.notifier)
        .create(_createInput());
    expect(
      container.read(createBudgetControllerProvider).status,
      CreateBudgetStatus.success,
    );
    expect(container.read(budgetsControllerProvider).items, hasLength(1));

    final budgetId = container
        .read(budgetsControllerProvider)
        .items
        .single
        .budget
        .id;
    await container
        .read(editBudgetControllerProvider.notifier)
        .update(
          UpdateBudgetInput(
            id: budgetId,
            categoryId: 'expense',
            month: 7,
            year: 2026,
            amount: 9000,
          ),
        );
    expect(
      container.read(editBudgetControllerProvider).status,
      EditBudgetStatus.success,
    );
    expect(
      container.read(budgetsControllerProvider).items.single.budget.amount,
      9000,
    );

    await container
        .read(deleteBudgetControllerProvider.notifier)
        .delete(budgetId);
    expect(
      container.read(deleteBudgetControllerProvider).status,
      DeleteBudgetStatus.success,
    );
    expect(container.read(budgetsControllerProvider).items, isEmpty);
  });

  test(
    'a related transaction refreshes progress on the active budget page',
    () async {
      final budget = Budget(
        id: 'budget',
        categoryId: 'expense',
        month: 7,
        year: 2026,
        amount: 1000,
        createdAt: DateTime(2026, 7),
        updatedAt: DateTime(2026, 7),
        isDeleted: false,
      );
      final resources = _resources(budgets: [budget]);
      final container = resources.container;
      addTearDown(container.dispose);
      container
          .read(appShellNavigationControllerProvider.notifier)
          .select(AppShellDestination.budgets);

      await container.read(budgetsControllerProvider.notifier).load();
      expect(
        container
            .read(budgetsControllerProvider)
            .items
            .single
            .progress
            .spentAmount,
        0,
      );

      final expense = _expense(amount: 400);
      await resources.transactionRepository.create(expense);
      await container
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: [expense]);

      expect(
        container
            .read(budgetsControllerProvider)
            .items
            .single
            .progress
            .spentAmount,
        400,
      );
      expect(
        container
            .read(budgetsControllerProvider)
            .items
            .single
            .progress
            .progress,
        0.4,
      );
    },
  );
}

({ProviderContainer container, TransactionRepositoryImpl transactionRepository})
_resources({List<Budget> budgets = const []}) {
  final budgetRepository = BudgetRepositoryImpl(
    BudgetMockDataSource(seed: budgets),
  );
  final categoryRepository = CategoryRepositoryImpl(
    CategoryMockDataSource(seed: const [_expenseCategory]),
  );
  final transactionRepository = TransactionRepositoryImpl(
    TransactionMockDataSource(initialTransactions: const []),
  );
  final container = ProviderContainer(
    overrides: [
      budgetRepositoryProvider.overrideWithValue(budgetRepository),
      categoryRepositoryProvider.overrideWithValue(categoryRepository),
      transactionRepositoryProvider.overrideWithValue(transactionRepository),
    ],
  );
  return (container: container, transactionRepository: transactionRepository);
}

const Category _expenseCategory = Category(
  id: 'expense',
  name: 'Groceries',
  icon: 'shopping_cart',
  color: 0xFF2E7D32,
  type: CategoryType.expense,
);

CreateBudgetInput _createInput() {
  return const CreateBudgetInput(
    categoryId: 'expense',
    month: 7,
    year: 2026,
    amount: 8000,
  );
}

Transaction _expense({required double amount}) {
  return Transaction(
    id: 'expense-transaction',
    accountId: 'account-1',
    creditCardId: null,
    amount: amount,
    transactionType: TransactionType.expense,
    categoryId: 'expense',
    merchant: 'Market',
    note: null,
    transactionDate: DateTime(2026, 7, 10),
    source: TransactionSource.manual,
    isDeleted: false,
  );
}
