import 'package:fincore_app/features/budgets/domain/entities/budget.dart';

abstract interface class BudgetDataSource {
  Future<List<Budget>> getAll();

  Future<Budget?> getById(String budgetId);

  Future<void> insert(Budget budget);

  Future<void> replace(Budget budget);

  Future<void> remove(String budgetId);

  Future<bool> exists({
    required String categoryId,
    required int month,
    required int year,
    String? excludingBudgetId,
  });
}

final class BudgetMockDataSource implements BudgetDataSource {
  BudgetMockDataSource({List<Budget>? seed})
    : _budgets = List.of(seed ?? _defaultBudgets);

  final List<Budget> _budgets;

  @override
  Future<List<Budget>> getAll() async {
    return List.unmodifiable(_budgets.where((budget) => !budget.isDeleted));
  }

  @override
  Future<Budget?> getById(String budgetId) async {
    for (final budget in _budgets) {
      if (budget.id == budgetId && !budget.isDeleted) {
        return budget;
      }
    }
    return null;
  }

  @override
  Future<void> insert(Budget budget) async {
    if (_budgets.any((item) => item.id == budget.id)) {
      throw StateError('Budget already exists.');
    }
    _budgets.add(budget);
  }

  @override
  Future<void> replace(Budget budget) async {
    final index = _budgets.indexWhere((item) => item.id == budget.id);
    if (index < 0 || _budgets[index].isDeleted) {
      throw StateError('Budget not found.');
    }
    _budgets[index] = budget;
  }

  @override
  Future<void> remove(String budgetId) async {
    final index = _budgets.indexWhere((item) => item.id == budgetId);
    if (index < 0 || _budgets[index].isDeleted) {
      throw StateError('Budget not found.');
    }
    _budgets[index] = _budgets[index].copyWith(
      isDeleted: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<bool> exists({
    required String categoryId,
    required int month,
    required int year,
    String? excludingBudgetId,
  }) async {
    return _budgets.any(
      (budget) =>
          !budget.isDeleted &&
          budget.id != excludingBudgetId &&
          budget.categoryId == categoryId &&
          budget.month == month &&
          budget.year == year,
    );
  }

  static final List<Budget> _defaultBudgets = [
    Budget(
      id: 'budget-grocery-2026-07',
      categoryId: 'category-grocery',
      month: 7,
      year: 2026,
      amount: 8000,
      createdAt: DateTime(2026, 7),
      updatedAt: DateTime(2026, 7),
      isDeleted: false,
    ),
    Budget(
      id: 'budget-utilities-2026-07',
      categoryId: 'category-utilities',
      month: 7,
      year: 2026,
      amount: 3500,
      createdAt: DateTime(2026, 7),
      updatedAt: DateTime(2026, 7),
      isDeleted: false,
    ),
    Budget(
      id: 'budget-food-2026-07',
      categoryId: 'category-food',
      month: 7,
      year: 2026,
      amount: 5000,
      createdAt: DateTime(2026, 7),
      updatedAt: DateTime(2026, 7),
      isDeleted: false,
    ),
  ];
}
