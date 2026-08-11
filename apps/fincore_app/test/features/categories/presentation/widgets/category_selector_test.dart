import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows only categories matching the requested type', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategorySelector(
            categories: const [
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
            type: CategoryType.expense,
            value: null,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Kategori yok'));
    await tester.pumpAndSettle();

    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Maaş'), findsNothing);
  });
}
