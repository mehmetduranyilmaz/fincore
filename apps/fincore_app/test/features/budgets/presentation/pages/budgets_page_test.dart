import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/budgets/data/datasources/budget_mock_data_source.dart';
import 'package:fincore_app/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:fincore_app/features/budgets/domain/entities/budget.dart';
import 'package:fincore_app/features/budgets/presentation/pages/budgets_page.dart';
import 'package:fincore_app/features/categories/data/datasources/category_mock_data_source.dart';
import 'package:fincore_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:fincore_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Turkish budget values and progress on phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('budgets_list_layout')), findsOneWidget);
    expect(find.text('Bütçeler'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('8.000,00 ₺'), findsOneWidget);
    expect(find.text('5.250,00 ₺'), findsOneWidget);
    expect(find.text('2.750,00 ₺'), findsOneWidget);
    expect(find.text('%66'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('uses a responsive grid on desktop', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('budgets_grid_layout')), findsOneWidget);
  });
}

Widget _app() {
  return ProviderScope(
    overrides: [
      budgetRepositoryProvider.overrideWithValue(
        BudgetRepositoryImpl(BudgetMockDataSource(seed: [_budget])),
      ),
      categoryRepositoryProvider.overrideWithValue(
        CategoryRepositoryImpl(CategoryMockDataSource(seed: const [_category])),
      ),
      transactionRepositoryProvider.overrideWithValue(
        TransactionRepositoryImpl(
          TransactionMockDataSource(initialTransactions: [_transaction]),
        ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: BudgetsPage()),
    ),
  );
}

final Budget _budget = Budget(
  id: 'budget',
  categoryId: 'category-grocery',
  month: 7,
  year: 2026,
  amount: 8000,
  createdAt: DateTime(2026, 7),
  updatedAt: DateTime(2026, 7),
  isDeleted: false,
);

const Category _category = Category(
  id: 'category-grocery',
  name: 'Groceries',
  icon: 'shopping_cart',
  color: 0xFF2E7D32,
  type: CategoryType.expense,
);

final Transaction _transaction = Transaction(
  id: 'transaction',
  accountId: 'account-1',
  creditCardId: null,
  amount: 5250,
  transactionType: TransactionType.expense,
  categoryId: 'category-grocery',
  merchant: 'Market',
  note: null,
  transactionDate: DateTime(2026, 7, 15),
  source: TransactionSource.manual,
  isDeleted: false,
);
