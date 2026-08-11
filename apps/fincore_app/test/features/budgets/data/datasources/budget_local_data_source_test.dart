import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:fincore_app/features/budgets/domain/entities/budget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('persists created and updated budgets', () async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final firstDataSource = BudgetLocalDataSource(storage);
    await firstDataSource.insert(_budget);
    await firstDataSource.replace(_budget.copyWith(amount: 2500));

    final secondDataSource = BudgetLocalDataSource(storage);
    final persisted = await secondDataSource.getById(_budget.id);

    expect(persisted?.amount, 2500);
    expect(
      await secondDataSource.exists(
        categoryId: _budget.categoryId,
        month: _budget.month,
        year: _budget.year,
      ),
      isTrue,
    );
  });

  test('soft deletion survives a new data source instance', () async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    final firstDataSource = BudgetLocalDataSource(storage);
    await firstDataSource.insert(_budget);
    await firstDataSource.remove(_budget.id);

    final secondDataSource = BudgetLocalDataSource(storage);

    expect(await secondDataSource.getAll(), isEmpty);
    expect(await secondDataSource.getById(_budget.id), isNull);
  });
}

final _budget = Budget(
  id: 'budget-test',
  categoryId: 'category-food',
  month: 8,
  year: 2026,
  amount: 2000,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
  isDeleted: false,
);
