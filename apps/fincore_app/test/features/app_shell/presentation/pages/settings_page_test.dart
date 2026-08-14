import 'package:fincore_app/features/app_shell/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows encrypted backup and restore actions', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: SettingsPage())),
      ),
    );

    expect(find.text('Şifreli Yedek Oluştur'), findsOneWidget);
    expect(find.text('Yedekten Geri Yükle'), findsOneWidget);
    expect(find.text('Yedekle'), findsOneWidget);
    expect(find.text('Geri Yükle'), findsOneWidget);
  });

  testWidgets('requires matching backup passwords of at least 8 characters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: SettingsPage())),
      ),
    );

    await tester.tap(find.text('Yedekle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('backup_password')), '1234567');
    await tester.enterText(
      find.byKey(const Key('backup_password_confirmation')),
      'başka-parola',
    );
    await tester.tap(find.byKey(const Key('backup_password_submit')));
    await tester.pump();

    expect(find.text('En az 8 karakter girin.'), findsOneWidget);
    expect(find.text('Parolalar eşleşmiyor.'), findsOneWidget);
  });
}
