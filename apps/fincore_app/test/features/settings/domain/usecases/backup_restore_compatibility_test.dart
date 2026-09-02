import 'package:fincore_app/features/settings/data/services/automatic_backup_runner.dart';
import 'package:fincore_app/features/settings/data/services/encrypted_backup_codec.dart';
import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_config_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_snapshot_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_target_gateway.dart';
import 'package:fincore_app/features/settings/domain/services/backup_file_gateway.dart';
import 'package:fincore_app/features/settings/domain/services/financial_backup_store.dart';
import 'package:fincore_app/features/settings/domain/usecases/create_financial_backup.dart';
import 'package:fincore_app/features/settings/domain/usecases/restore_financial_backup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const password = 'fixture-password';
  const fixture = <String, String?>{
    'accounts_v1': '[{"id":"account-1"}]',
    'transactions_v1': '[{"id":"transaction-1","amount":125.5}]',
  };

  test(
    'manual backup is accepted by the production restore pipeline',
    () async {
      final source = _FinancialStore(fixture);
      final file = _FileGateway();
      final codec = EncryptedBackupCodec();
      await CreateFinancialBackupUseCase(
        source,
        codec,
        file,
        clock: () => DateTime.utc(2026, 9, 2, 12),
      ).execute(password);

      final restored = _FinancialStore(const {});
      file.pickedBytes = file.sharedBytes;
      expect(
        await RestoreFinancialBackupUseCase(
          restored,
          codec,
          file,
        ).execute(password),
        isTrue,
      );
      expect(restored.data, fixture);
    },
  );

  test(
    'automatic and Drive-target bytes are accepted by the same restore pipeline',
    () async {
      final codec = EncryptedBackupCodec();
      final config = _ConfigStore(password);
      final snapshot = _SnapshotStore();
      final drive = _TargetGateway();
      expect(
        await AutomaticBackupRunner(
          config,
          _FinancialStore(fixture),
          codec,
          snapshot,
          drive,
          clock: () => DateTime(2026, 9, 2, 2),
        ).run(),
        isTrue,
      );
      expect(snapshot.bytes, drive.bytes);

      for (final bytes in [snapshot.bytes!, drive.bytes!]) {
        final restored = _FinancialStore(const {});
        final file = _FileGateway()..pickedBytes = bytes;
        expect(
          await RestoreFinancialBackupUseCase(
            restored,
            codec,
            file,
          ).execute(password),
          isTrue,
        );
        expect(restored.data, fixture);
      }
    },
  );
}

final class _FinancialStore implements FinancialBackupStore {
  _FinancialStore(this.data);

  Map<String, String?> data;

  @override
  Future<Map<String, String?>> readFinancialData() async => Map.of(data);

  @override
  Future<void> replaceFinancialData(Map<String, String?> data) async {
    this.data = Map.of(data);
  }
}

final class _FileGateway implements BackupFileGateway {
  List<int>? sharedBytes;
  List<int>? pickedBytes;

  @override
  Future<List<int>?> pick() async => pickedBytes;

  @override
  Future<void> share({
    required String fileName,
    required List<int> bytes,
  }) async {
    sharedBytes = List.of(bytes);
  }
}

final class _ConfigStore implements AutomaticBackupConfigStore {
  _ConfigStore(this.password);

  final String password;
  AutomaticBackupConfiguration configuration =
      const AutomaticBackupConfiguration(
        targetUri:
            'content://com.google.android.apps.docs.storage/document/root',
        targetName: 'Fincore',
        hour: 2,
        minute: 0,
      );

  @override
  Future<void> clear() async {}

  @override
  Future<AutomaticBackupConfiguration?> readConfiguration() async =>
      configuration;

  @override
  Future<String?> readPassword() async => password;

  @override
  Future<void> save({
    required AutomaticBackupConfiguration configuration,
    required String password,
  }) async {}

  @override
  Future<void> updateConfiguration(
    AutomaticBackupConfiguration configuration,
  ) async {
    this.configuration = configuration;
  }
}

final class _SnapshotStore implements AutomaticBackupSnapshotStore {
  List<int>? bytes;

  @override
  Future<bool> exists() async => bytes != null;

  @override
  Future<List<int>?> readLatest() async => bytes;

  @override
  Future<void> writeLatest(List<int> bytes) async =>
      this.bytes = List.of(bytes);
}

final class _TargetGateway implements AutomaticBackupTargetGateway {
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
    this.bytes = List.of(bytes);
  }
}
