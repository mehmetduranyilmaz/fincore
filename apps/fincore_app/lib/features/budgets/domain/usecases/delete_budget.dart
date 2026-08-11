import 'package:fincore_app/features/budgets/domain/repositories/budget_repository.dart';

final class DeleteBudgetUseCase {
  const DeleteBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<void> execute(String budgetId) async {
    if (budgetId.trim().isEmpty) {
      throw ArgumentError.value(budgetId, 'budgetId');
    }
    await _repository.delete(budgetId);
  }
}
