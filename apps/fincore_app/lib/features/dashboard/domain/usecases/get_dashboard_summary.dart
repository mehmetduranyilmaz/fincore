import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/dashboard/domain/repositories/dashboard_repository.dart';

final class GetDashboardSummary {
  const GetDashboardSummary(this._repository);

  final DashboardRepository _repository;

  Future<DashboardSummary> execute() => _repository.getSummary();
}
