import 'package:fincore_app/features/budgets/domain/entities/budget.dart';

abstract interface class BudgetRepository {
  Future<List<Budget>> getAll();

  Future<Budget?> getById(String budgetId);

  Future<void> create(Budget budget);

  Future<void> update(Budget budget);

  Future<void> delete(String budgetId);

  Future<bool> exists({
    required String categoryId,
    required int month,
    required int year,
    String? excludingBudgetId,
  });
}
