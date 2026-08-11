import 'package:fincore_app/features/budgets/domain/entities/budget.dart';
import 'package:fincore_app/features/budgets/domain/repositories/budget_repository.dart';
import 'package:fincore_app/features/budgets/domain/usecases/budget_validator.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';

typedef BudgetClock = DateTime Function();
typedef BudgetIdGenerator = String Function();

final class CreateBudgetInput {
  const CreateBudgetInput({
    required this.categoryId,
    required this.month,
    required this.year,
    required this.amount,
  });

  final String categoryId;
  final int month;
  final int year;
  final double amount;
}

final class CreateBudgetUseCase {
  CreateBudgetUseCase(
    this._budgetRepository,
    this._categoryRepository, {
    BudgetClock? clock,
    BudgetIdGenerator? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _generateId;

  final BudgetRepository _budgetRepository;
  final CategoryRepository _categoryRepository;
  final BudgetClock _clock;
  final BudgetIdGenerator _idGenerator;

  Future<Budget> execute(CreateBudgetInput input) async {
    BudgetValidator.validateAmount(input.amount);
    BudgetValidator.validatePeriod(month: input.month, year: input.year);
    await BudgetValidator.validateCategory(
      input.categoryId,
      _categoryRepository,
    );
    await _ensureUnique(
      categoryId: input.categoryId,
      month: input.month,
      year: input.year,
    );

    final now = _clock();
    final budget = Budget(
      id: _idGenerator(),
      categoryId: input.categoryId,
      month: input.month,
      year: input.year,
      amount: input.amount,
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
    );

    await _budgetRepository.create(budget);
    return budget;
  }

  Future<void> _ensureUnique({
    required String categoryId,
    required int month,
    required int year,
  }) async {
    final exists = await _budgetRepository.exists(
      categoryId: categoryId,
      month: month,
      year: year,
    );
    if (exists) {
      throw StateError('Budget already exists.');
    }
  }

  static String _generateId() {
    return 'budget-${DateTime.now().microsecondsSinceEpoch}';
  }
}
