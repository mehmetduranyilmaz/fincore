import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fincore_app/features/dashboard/presentation/providers/dashboard_summary_provider.dart';
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
    expect(find.text('Net Değer'), findsOneWidget);
    expect(find.text('Toplam Hesap Bakiyesi'), findsOneWidget);
    expect(find.text('Toplam Kredi Kartı Borcu'), findsOneWidget);
    expect(find.text('Aylık Gelir'), findsOneWidget);
    expect(find.text('Aylık Gider'), findsOneWidget);
    expect(find.text('Aylık Nakit Akışı'), findsOneWidget);
    expect(find.text('İşlem Sayısı'), findsOneWidget);
    expect(find.text('95.000,00 ₺'), findsOneWidget);
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
    expect(find.text('100.000,00 ₺'), findsOneWidget);
    expect(find.text('5.000,00 ₺'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });
}

Widget _dashboardApp() {
  return ProviderScope(
    overrides: [
      dashboardSummaryProvider.overrideWith(
        (ref) async => createDashboardSummary(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: DashboardPage()),
    ),
  );
}
