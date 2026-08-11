import 'package:fincore_app/features/budgets/domain/entities/budget.dart';
import 'package:fincore_app/features/budgets/domain/repositories/budget_repository.dart';

final class GetBudgetsUseCase {
  const GetBudgetsUseCase(this._repository);

  final BudgetRepository _repository;

  Future<List<Budget>> execute() async {
    final budgets = await _repository.getAll();
    return List.unmodifiable(budgets.where((budget) => !budget.isDeleted));
  }
}
