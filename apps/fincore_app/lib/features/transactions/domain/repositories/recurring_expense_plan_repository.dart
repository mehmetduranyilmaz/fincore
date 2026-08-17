import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';

abstract interface class RecurringExpensePlanRepository {
  Future<List<RecurringExpensePlan>> getPlans();

  Future<void> create(RecurringExpensePlan plan);

  Future<void> update(RecurringExpensePlan plan);

  Future<void> delete(String planId);
}
