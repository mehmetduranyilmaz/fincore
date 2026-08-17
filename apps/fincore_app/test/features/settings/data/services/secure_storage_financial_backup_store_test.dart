import 'package:fincore_app/features/settings/data/services/backup_key_value_store.dart';
import 'package:fincore_app/features/settings/data/services/secure_storage_financial_backup_store.dart';
import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads only the explicit financial allowlist', () async {
    final storage = _MemoryStore({
      ..._validData,
      'access_token': 'secret-token',
      'refresh_token': 'secret-refresh-token',
    });
    final store = SecureStorageFinancialBackupStore(storage);

    final result = await store.readFinancialData();

    expect(
      result.keys.toSet(),
      SecureStorageFinancialBackupStore.financialKeys,
    );
    expect(result, isNot(contains('access_token')));
    expect(result, isNot(contains('refresh_token')));
  });

  test('validates all records before replacing current data', () async {
    final storage = _MemoryStore(_validData);
    final store = SecureStorageFinancialBackupStore(storage);
    final invalid = {..._validData, 'accounts_v1': '{not-a-list}'};

    await expectLater(
      store.replaceFinancialData(invalid),
      throwsA(isA<BackupException>()),
    );
    expect(storage.values, _validData);
  });

  test('rolls back every key if persistence fails', () async {
    final original = {..._validData};
    final storage = _MemoryStore(original)
      ..failOnceOnKey = SecureStorageFinancialBackupStore.customersKey;
    final store = SecureStorageFinancialBackupStore(storage);
    final replacement = {
      ..._validData,
      SecureStorageFinancialBackupStore.categoryDefaultsVersionKey: '5',
    };

    await expectLater(
      store.replaceFinancialData(replacement),
      throwsA(isA<BackupException>()),
    );
    expect(storage.values, original);
  });

  test('restores a backup created before recurring plans existed', () async {
    final legacy = Map<String, String?>.from(_validData)
      ..remove(SecureStorageFinancialBackupStore.recurringExpensePlansKey);
    final storage = _MemoryStore(_validData);
    final store = SecureStorageFinancialBackupStore(storage);

    await store.replaceFinancialData(legacy);

    expect(
      await storage.read(
        SecureStorageFinancialBackupStore.recurringExpensePlansKey,
      ),
      isNull,
    );
  });
}

final Map<String, String?> _validData = {
  for (final key in SecureStorageFinancialBackupStore.financialKeys)
    key: key == SecureStorageFinancialBackupStore.categoryDefaultsVersionKey
        ? '4'
        : '[]',
};

final class _MemoryStore implements BackupKeyValueStore {
  _MemoryStore(Map<String, String?> seed) : values = {...seed};

  final Map<String, String?> values;
  String? failOnceOnKey;

  @override
  Future<void> delete(String key) async {
    _failIfNeeded(key);
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    _failIfNeeded(key);
    values[key] = value;
  }

  void _failIfNeeded(String key) {
    if (failOnceOnKey != key) return;
    failOnceOnKey = null;
    throw StateError('simulated write failure');
  }
}
