import 'package:fincore_app/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses NavigationBar on compact screens', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(599, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AppShellPage())),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('uses NavigationRail on expanded screens', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AppShellPage())),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
