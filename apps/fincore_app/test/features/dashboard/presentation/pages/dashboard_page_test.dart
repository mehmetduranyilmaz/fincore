import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:fincore_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dashboard_test_data.dart';

void main() {
  testWidgets('renders dashboard sections in the mobile layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_dashboardApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_mobile_layout')), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('Upcoming Payments'), findsOneWidget);
    expect(find.text('Recent Transactions'), findsOneWidget);
    expect(find.text('Category Spending'), findsOneWidget);
    expect(find.text('Test Transaction'), findsOneWidget);
  });

  testWidgets('renders dashboard sections in the desktop layout', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_dashboardApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_desktop_layout')), findsOneWidget);
    expect(find.text('Test Payment'), findsOneWidget);
    expect(find.text('Test Category'), findsOneWidget);
  });
}

Widget _dashboardApp() {
  return ProviderScope(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(
        _DashboardRepository(createDashboardSummary()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: DashboardPage()),
    ),
  );
}

final class _DashboardRepository implements DashboardRepository {
  const _DashboardRepository(this.summary);

  final DashboardSummary summary;

  @override
  Future<DashboardSummary> getSummary() async => summary;
}
