import 'package:fincore_app/features/settings/data/services/automatic_backup_runner.dart';
import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_config_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_snapshot_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_target_gateway.dart';
import 'package:fincore_app/features/settings/domain/services/backup_codec.dart';
import 'package:fincore_app/features/settings/domain/services/financial_backup_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a full snapshot and overwrites the selected target', () async {
    final now = DateTime(2026, 8, 17, 2, 0);
    final configStore = _ConfigStore(
      const AutomaticBackupConfiguration(
        targetUri: 'content://drive/Hesabim',
        targetName: 'Hesabım',
        hour: 2,
        minute: 0,
      ),
      'yedek-parolasi',
    );
    final snapshot = _SnapshotStore();
    final target = _TargetGateway();
    final runner = AutomaticBackupRunner(
      configStore,
      _FinancialStore(),
      _Codec(),
      snapshot,
      target,
      clock: () => now,
    );

    expect(await runner.run(), isTrue);

    expect(snapshot.bytes, [7, 8, 9]);
    expect(target.uri, 'content://drive/Hesabim');
    expect(target.bytes, [7, 8, 9]);
    expect(configStore.configuration?.lastSuccessAt, now);
    expect(configStore.configuration?.lastError, isNull);
  });

  test('does nothing when automatic backup is disabled', () async {
    final runner = AutomaticBackupRunner(
      _ConfigStore(null, null),
      _FinancialStore(),
      _Codec(),
      _SnapshotStore(),
      _TargetGateway(),
    );

    expect(await runner.run(), isFalse);
  });
}

final class _ConfigStore implements AutomaticBackupConfigStore {
  _ConfigStore(this.configuration, this.password);

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

final class _FinancialStore implements FinancialBackupStore {
  @override
  Future<Map<String, String?>> readFinancialData() async => {
    'transactions_v1': '[]',
  };

  @override
  Future<void> replaceFinancialData(Map<String, String?> data) async {}
}

final class _Codec implements BackupCodec {
  @override
  Future<Map<String, String?>> decrypt({
    required List<int> bytes,
    required String password,
  }) async => {};

  @override
  Future<List<int>> encrypt({
    required Map<String, String?> data,
    required String password,
    required DateTime createdAt,
  }) async {
    expect(data, {'transactions_v1': '[]'});
    expect(password, 'yedek-parolasi');
    return [7, 8, 9];
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
  String? uri;
  List<int>? bytes;

  @override
  Future<bool> hasWritePermission(String uri) async => true;

  @override
  Future<AutomaticBackupTarget?> pickDirectory({String? initialUri}) async =>
      null;

  @override
  Future<void> releasePermission(String uri) async {}

  @override
  Future<void> writeLatest(String directoryUri, List<int> bytes) async {
    uri = directoryUri;
    this.bytes = bytes;
  }
}
