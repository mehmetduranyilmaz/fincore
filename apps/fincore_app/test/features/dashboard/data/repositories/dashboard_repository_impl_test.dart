import 'package:fincore_app/features/dashboard/data/datasources/dashboard_mock_data_source.dart';
import 'package:fincore_app/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dashboard_test_data.dart';

void main() {
  test('returns the summary provided by the data source', () async {
    final summary = createDashboardSummary();
    final dataSource = _DashboardDataSource(summary);
    final repository = DashboardRepositoryImpl(dataSource);

    final result = await repository.getSummary();

    expect(result, same(summary));
    expect(dataSource.callCount, 1);
  });
}

final class _DashboardDataSource implements DashboardDataSource {
  _DashboardDataSource(this.summary);

  final DashboardSummary summary;
  int callCount = 0;

  @override
  Future<DashboardSummary> getSummary() async {
    callCount++;
    return summary;
  }
}
