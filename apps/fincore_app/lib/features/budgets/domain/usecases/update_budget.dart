import 'package:fincore_app/features/budgets/domain/entities/budget.dart';
import 'package:fincore_app/features/budgets/domain/repositories/budget_repository.dart';
import 'package:fincore_app/features/budgets/domain/usecases/budget_validator.dart';
import 'package:fincore_app/features/budgets/domain/usecases/create_budget.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';

final class UpdateBudgetInput {
  const UpdateBudgetInput({
    required this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.amount,
  });

  final String id;
  final String categoryId;
  final int month;
  final int year;
  final double amount;
}

final class UpdateBudgetUseCase {
  UpdateBudgetUseCase(
    this._budgetRepository,
    this._categoryRepository, {
    BudgetClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final BudgetRepository _budgetRepository;
  final CategoryRepository _categoryRepository;
  final BudgetClock _clock;

  Future<Budget> execute(UpdateBudgetInput input) async {
    final existing = await _budgetRepository.getById(input.id);
    if (existing == null || existing.isDeleted) {
      throw StateError('Budget not found.');
    }

    BudgetValidator.validateAmount(input.amount);
    BudgetValidator.validatePeriod(month: input.month, year: input.year);
    await BudgetValidator.validateCategory(
      input.categoryId,
      _categoryRepository,
    );

    final duplicate = await _budgetRepository.exists(
      categoryId: input.categoryId,
      month: input.month,
      year: input.year,
      excludingBudgetId: input.id,
    );
    if (duplicate) {
      throw StateError('Budget already exists.');
    }

    final budget = existing.copyWith(
      categoryId: input.categoryId,
      month: input.month,
      year: input.year,
      amount: input.amount,
      updatedAt: _clock(),
    );
    await _budgetRepository.update(budget);
    return budget;
  }
}
