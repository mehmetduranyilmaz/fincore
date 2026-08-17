import 'package:fincore_app/features/settings/data/services/backup_key_value_store.dart';
import 'package:fincore_app/features/settings/data/services/secure_storage_automatic_backup_config_store.dart';
import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores configuration separately from the backup password', () async {
    final storage = _MemoryStore();
    final store = SecureStorageAutomaticBackupConfigStore(storage);
    final success = DateTime(2026, 8, 17, 2, 5);

    await store.save(
      configuration: AutomaticBackupConfiguration(
        targetUri: 'content://drive/fincore',
        targetName: 'Google Drive / Hesabım',
        hour: 2,
        minute: 30,
        lastAttemptAt: success,
        lastSuccessAt: success,
      ),
      password: 'güvenli-parola',
    );

    final restored = await store.readConfiguration();
    expect(restored?.targetUri, 'content://drive/fincore');
    expect(restored?.targetName, 'Google Drive / Hesabım');
    expect(restored?.timeLabel, '02:30');
    expect(restored?.lastSuccessAt, success);
    expect(await store.readPassword(), 'güvenli-parola');
    expect(
      storage.values[SecureStorageAutomaticBackupConfigStore.configurationKey],
      isNot(contains('güvenli-parola')),
    );
  });

  test('clear removes configuration and password', () async {
    final storage = _MemoryStore();
    final store = SecureStorageAutomaticBackupConfigStore(storage);
    await store.save(
      configuration: const AutomaticBackupConfiguration(
        targetUri: 'content://device/backups',
        targetName: 'Backups',
        hour: 1,
        minute: 0,
      ),
      password: '12345678',
    );

    await store.clear();

    expect(await store.readConfiguration(), isNull);
    expect(await store.readPassword(), isNull);
  });
}

final class _MemoryStore implements BackupKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
