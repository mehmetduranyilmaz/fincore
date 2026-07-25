import 'package:fincore_app/features/dashboard/data/datasources/dashboard_mock_data_source.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/dashboard/domain/repositories/dashboard_repository.dart';

final class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._dataSource);

  final DashboardDataSource _dataSource;

  @override
  Future<DashboardSummary> getSummary() => _dataSource.getSummary();
}
