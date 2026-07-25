import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppCard renders its child with configurable padding', (
    tester,
  ) async {
    const padding = EdgeInsets.all(AppSpacing.lg);

    await tester.pumpWidget(
      _testApp(const AppCard(padding: padding, child: Text('Card content'))),
    );

    expect(find.byType(Card), findsOneWidget);
    expect(find.text('Card content'), findsOneWidget);
    expect(tester.widget<AppCard>(find.byType(AppCard)).padding, padding);
  });

  testWidgets('AppButton supports loading and disabled states', (tester) async {
    var pressCount = 0;

    await tester.pumpWidget(
      _testApp(
        AppButton(
          label: 'Save',
          isLoading: true,
          onPressed: () => pressCount++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      null,
    );

    await tester.pumpWidget(
      _testApp(
        AppButton(
          label: 'Save',
          isEnabled: false,
          onPressed: () => pressCount++,
        ),
      ),
    );

    await tester.tap(find.text('Save'));

    expect(pressCount, 0);
  });

  testWidgets('AppTextField renders shared decoration and error text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(const AppTextField(label: 'Email', errorText: 'Invalid email')),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.decoration?.labelText, 'Email');
    expect(find.text('Invalid email'), findsOneWidget);
  });

  testWidgets('AppEmptyState renders icon, title, and description', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        const AppEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No data',
          description: 'Items will appear here.',
        ),
      ),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('No data'), findsOneWidget);
    expect(find.text('Items will appear here.'), findsOneWidget);
  });

  testWidgets('AppLoadingView renders a centered progress indicator', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const AppLoadingView()));

    expect(find.byType(Center), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppErrorView invokes retry callback', (tester) async {
    var retryCount = 0;

    await tester.pumpWidget(
      _testApp(
        AppErrorView(message: 'Unable to load', onRetry: () => retryCount++),
      ),
    );

    await tester.tap(find.text('Retry'));

    expect(find.text('Unable to load'), findsOneWidget);
    expect(retryCount, 1);
  });

  testWidgets('AppSectionHeader renders an optional action', (tester) async {
    await tester.pumpWidget(
      _testApp(
        AppSectionHeader(
          title: 'Recent activity',
          action: TextButton(onPressed: () {}, child: const Text('View all')),
        ),
      ),
    );

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('View all'), findsOneWidget);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}
