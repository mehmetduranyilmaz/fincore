import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/categories/data/datasources/category_mock_data_source.dart';
import 'package:fincore_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/presentation/pages/categories_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders category list with type labels', (tester) async {
    final repository = CategoryRepositoryImpl(
      CategoryMockDataSource(
        seed: const [
          Category(
            id: 'income',
            name: 'Salary',
            icon: 'payments',
            color: 0xFF1565C0,
            type: CategoryType.income,
          ),
          Category(
            id: 'expense',
            name: 'Groceries',
            icon: 'shopping_cart',
            color: 0xFF2E7D32,
            type: CategoryType.expense,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [categoryRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: CategoriesPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kategoriler'), findsOneWidget);
    expect(find.text('Maaş'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Gelir'), findsOneWidget);
    expect(find.text('Gider'), findsOneWidget);
  });
}
