import 'package:fincore_app/features/settings/data/services/automatic_backup_manager_impl.dart';
import 'package:fincore_app/features/settings/data/services/automatic_backup_runner.dart';
import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_config_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_scheduler.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_snapshot_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_target_gateway.dart';
import 'package:fincore_app/features/settings/domain/services/backup_codec.dart';
import 'package:fincore_app/features/settings/domain/services/financial_backup_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'enables, immediately backs up, schedules and disables safely',
    () async {
      final config = _ConfigStore();
      final snapshot = _SnapshotStore();
      final target = _TargetGateway();
      final scheduler = _Scheduler();
      final financial = _FinancialStore();
      final codec = _Codec();
      final runner = AutomaticBackupRunner(
        config,
        financial,
        codec,
        snapshot,
        target,
        clock: () => DateTime(2026, 8, 17, 2),
      );
      final manager = AutomaticBackupManagerImpl(
        config,
        runner,
        scheduler,
        snapshot,
        target,
        codec,
        financial,
      );

      await manager.enable(
        target: const AutomaticBackupTarget(
          uri: 'content://drive/Hesabim',
          name: 'Google Drive / Hesabım',
        ),
        password: 'güvenli-parola',
        hour: 2,
        minute: 30,
      );

      expect(config.configuration?.lastSuccessAt, DateTime(2026, 8, 17, 2));
      expect(snapshot.bytes, [4, 2]);
      expect(target.bytes, [4, 2]);
      expect(scheduler.scheduledTime, (2, 30));
      expect((await manager.getOverview()).isEnabled, isTrue);

      await manager.disable();

      expect(config.configuration, isNull);
      expect(config.password, isNull);
      expect(scheduler.cancelled, isTrue);
      expect(target.releasedUri, 'content://drive/Hesabim');
      expect(snapshot.bytes, [
        4,
        2,
      ], reason: 'Existing backup must be preserved.');
    },
  );

  test('restores the internal encrypted snapshot', () async {
    final config = _ConfigStore();
    final snapshot = _SnapshotStore()..bytes = [4, 2];
    final target = _TargetGateway();
    final scheduler = _Scheduler();
    final financial = _FinancialStore();
    final codec = _Codec();
    final manager = AutomaticBackupManagerImpl(
      config,
      AutomaticBackupRunner(config, financial, codec, snapshot, target),
      scheduler,
      snapshot,
      target,
      codec,
      financial,
    );

    expect(await manager.restoreLocalSnapshot('güvenli-parola'), isTrue);
    expect(financial.restored, {'transactions_v1': '[]'});
  });
}

final class _ConfigStore implements AutomaticBackupConfigStore {
  AutomaticBackupConfiguration? configuration;
  String? password;

  @override
  Future<void> clear() async {
    configuration = null;
    password = null;
  }

  @override
  Future<AutomaticBackupConfiguration?> readConfiguration() async =>
      configuration;

  @override
  Future<String?> readPassword() async => password;

  @override
  Future<void> save({
    required AutomaticBackupConfiguration configuration,
    required String password,
  }) async {
    this.configuration = configuration;
    this.password = password;
  }

  @override
  Future<void> updateConfiguration(
    AutomaticBackupConfiguration configuration,
  ) async => this.configuration = configuration;
}

final class _Scheduler implements AutomaticBackupScheduler {
  (int, int)? scheduledTime;
  bool cancelled = false;

  @override
  Future<void> cancel() async => cancelled = true;

  @override
  Future<void> schedule({
    required int hour,
    required int minute,
    required String targetUri,
  }) async {
    scheduledTime = (hour, minute);
  }
}

final class _SnapshotStore implements AutomaticBackupSnapshotStore {
  List<int>? bytes;

  @override
  Future<bool> exists() async => bytes != null;

  @override
  Future<List<int>?> readLatest() async => bytes;

  @override
  Future<void> writeLatest(List<int> bytes) async => this.bytes = bytes;
}

final class _TargetGateway implements AutomaticBackupTargetGateway {
  List<int>? bytes;
  String? releasedUri;

  @override
  Future<bool> hasWritePermission(String uri) async => true;

  @override
  Future<AutomaticBackupTarget?> pickDirectory({String? initialUri}) async =>
      null;

  @override
  Future<void> releasePermission(String uri) async => releasedUri = uri;

  @override
  Future<void> writeLatest(String directoryUri, List<int> bytes) async =>
      this.bytes = bytes;
}

final class _Codec implements BackupCodec {
  @override
  Future<Map<String, String?>> decrypt({
    required List<int> bytes,
    required String password,
  }) async {
    expect(password, 'güvenli-parola');
    return {'transactions_v1': '[]'};
  }

  @override
  Future<List<int>> encrypt({
    required Map<String, String?> data,
    required String password,
    required DateTime createdAt,
  }) async => [4, 2];
}

final class _FinancialStore implements FinancialBackupStore {
  Map<String, String?>? restored;

  @override
  Future<Map<String, String?>> readFinancialData() async => {
    'transactions_v1': '[]',
  };

  @override
  Future<void> replaceFinancialData(Map<String, String?> data) async =>
      restored = data;
}
