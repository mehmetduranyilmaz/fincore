import 'package:fincore_app/core/storage/secure_storage_service.dart';

abstract interface class BackupKeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

final class SecureBackupKeyValueStore implements BackupKeyValueStore {
  const SecureBackupKeyValueStore(this._storage);

  final SecureStorageService _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
