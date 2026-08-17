import 'package:fincore_app/features/app_shell/presentation/pages/settings_page.dart';
import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_manager.dart';
import 'package:fincore_app/features/settings/presentation/providers/backup_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows encrypted backup and restore actions', (tester) async {
    await _pumpSettings(tester);

    expect(find.text('Şifreli Yedek Oluştur'), findsOneWidget);
    expect(find.text('Yedekten Geri Yükle'), findsOneWidget);
    expect(find.text('Yedekle'), findsOneWidget);
    expect(find.text('Geri Yükle'), findsOneWidget);
  });

  testWidgets('requires matching backup passwords of at least 8 characters', (
    tester,
  ) async {
    await _pumpSettings(tester);

    await tester.ensureVisible(find.text('Yedekle'));
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

  testWidgets('shows enabled automatic backup status and latest snapshot', (
    tester,
  ) async {
    await _pumpSettings(
      tester,
      overview: AutomaticBackupOverview(
        configuration: AutomaticBackupConfiguration(
          targetUri: 'content://drive/hesabim',
          targetName: 'Google Drive / Hesabım',
          hour: 2,
          minute: 30,
          lastSuccessAt: DateTime(2026, 8, 17, 2, 31),
        ),
        localSnapshotAvailable: true,
      ),
    );

    expect(find.text('Otomatik Şifreli Yedek'), findsOneWidget);
    expect(find.text('Açık'), findsOneWidget);
    expect(find.text('Her gün yaklaşık 02:30'), findsOneWidget);
    expect(find.text('Google Drive / Hesabım'), findsOneWidget);
    expect(find.text('Son Otomatik Yedeği Geri Yükle'), findsOneWidget);
    expect(find.text('Şimdi Yedekle'), findsOneWidget);
  });
}

Future<void> _pumpSettings(
  WidgetTester tester, {
  AutomaticBackupOverview overview = const AutomaticBackupOverview(
    configuration: null,
    localSnapshotAvailable: false,
  ),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        automaticBackupManagerProvider.overrideWithValue(
          _FakeAutomaticBackupManager(overview),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: SettingsPage())),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FakeAutomaticBackupManager implements AutomaticBackupManager {
  _FakeAutomaticBackupManager(this.overview);

  AutomaticBackupOverview overview;

  @override
  Future<void> disable() async {}

  @override
  Future<void> enable({
    required AutomaticBackupTarget target,
    required String password,
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<AutomaticBackupOverview> getOverview() async => overview;

  @override
  Future<bool> restoreLocalSnapshot(String password) async => true;

  @override
  Future<void> runNow() async {}

  @override
  Future<AutomaticBackupTarget?> selectTarget({String? initialUri}) async =>
      const AutomaticBackupTarget(uri: 'content://drive', name: 'Drive');
}
