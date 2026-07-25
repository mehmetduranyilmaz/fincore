import 'dart:async';

import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:fincore_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dashboard_test_data.dart';

void main() {
  test('moves from initial to loading and loaded', () async {
    final completer = Completer<DashboardSummary>();
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          _DashboardRepository(completer.future),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(dashboardControllerProvider).status,
      DashboardStatus.initial,
    );

    final load = container.read(dashboardControllerProvider.notifier).load();

    expect(
      container.read(dashboardControllerProvider).status,
      DashboardStatus.loading,
    );

    final summary = createDashboardSummary();
    completer.complete(summary);
    await load;

    final state = container.read(dashboardControllerProvider);

    expect(state.status, DashboardStatus.loaded);
    expect(state.summary, same(summary));
    expect(state.errorMessage, isNull);
  });

  test('moves to failure when the repository throws', () async {
    final container = ProviderContainer(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          _DashboardRepository(Future.error(Exception('Failed'))),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(dashboardControllerProvider.notifier).load();

    final state = container.read(dashboardControllerProvider);

    expect(state.status, DashboardStatus.failure);
    expect(state.summary, isNull);
    expect(state.errorMessage, isNotEmpty);
  });
}

final class _DashboardRepository implements DashboardRepository {
  const _DashboardRepository(this.result);

  final Future<DashboardSummary> result;

  @override
  Future<DashboardSummary> getSummary() => result;
}
