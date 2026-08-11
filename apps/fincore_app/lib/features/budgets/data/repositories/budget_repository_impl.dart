import 'package:fincore_app/features/budgets/data/datasources/budget_mock_data_source.dart';
import 'package:fincore_app/features/budgets/domain/entities/budget.dart';
import 'package:fincore_app/features/budgets/domain/repositories/budget_repository.dart';

final class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._dataSource);

  final BudgetDataSource _dataSource;

  @override
  Future<List<Budget>> getAll() => _dataSource.getAll();

  @override
  Future<Budget?> getById(String budgetId) => _dataSource.getById(budgetId);

  @override
  Future<void> create(Budget budget) => _dataSource.insert(budget);

  @override
  Future<void> update(Budget budget) => _dataSource.replace(budget);

  @override
  Future<void> delete(String budgetId) => _dataSource.remove(budgetId);

  @override
  Future<bool> exists({
    required String categoryId,
    required int month,
    required int year,
    String? excludingBudgetId,
  }) {
    return _dataSource.exists(
      categoryId: categoryId,
      month: month,
      year: year,
      excludingBudgetId: excludingBudgetId,
    );
  }
}
