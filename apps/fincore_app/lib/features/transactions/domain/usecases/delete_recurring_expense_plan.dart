import 'package:fincore_app/features/transactions/domain/repositories/recurring_expense_plan_repository.dart';

final class DeleteRecurringExpensePlanUseCase {
  const DeleteRecurringExpensePlanUseCase(this._repository);

  final RecurringExpensePlanRepository _repository;

  Future<void> execute(String planId) async {
    if (planId.trim().isEmpty) throw ArgumentError.value(planId, 'planId');
    await _repository.delete(planId);
  }
}
