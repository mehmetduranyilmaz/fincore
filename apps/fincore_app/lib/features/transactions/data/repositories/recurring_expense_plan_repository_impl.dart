import 'package:fincore_app/features/transactions/data/datasources/recurring_expense_plan_local_data_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/repositories/recurring_expense_plan_repository.dart';

final class RecurringExpensePlanRepositoryImpl
    implements RecurringExpensePlanRepository {
  const RecurringExpensePlanRepositoryImpl(this._dataSource);

  final RecurringExpensePlanDataSource _dataSource;

  @override
  Future<List<RecurringExpensePlan>> getPlans() => _dataSource.getPlans();

  @override
  Future<void> create(RecurringExpensePlan plan) => _dataSource.insert(plan);

  @override
  Future<void> update(RecurringExpensePlan plan) => _dataSource.replace(plan);

  @override
  Future<void> delete(String planId) => _dataSource.remove(planId);
}
