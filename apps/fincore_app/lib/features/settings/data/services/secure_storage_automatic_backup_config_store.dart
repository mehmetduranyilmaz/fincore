import 'dart:convert';

import 'package:fincore_app/features/settings/data/services/backup_key_value_store.dart';
import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';
import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_config_store.dart';

final class SecureStorageAutomaticBackupConfigStore
    implements AutomaticBackupConfigStore {
  const SecureStorageAutomaticBackupConfigStore(this._storage);

  static const String configurationKey = 'automatic_backup_configuration_v1';
  static const String passwordKey = 'automatic_backup_password_v1';

  final BackupKeyValueStore _storage;

  @override
  Future<AutomaticBackupConfiguration?> readConfiguration() async {
    final value = await _storage.read(configurationKey);
    if (value == null) return null;
    try {
      final json = jsonDecode(value);
      if (json is! Map || json['version'] != 1) {
        throw const FormatException('Invalid automatic backup config.');
      }
      final targetUri = json['targetUri'];
      final targetName = json['targetName'];
      final hour = json['hour'];
      final minute = json['minute'];
      if (targetUri is! String ||
          targetUri.isEmpty ||
          targetName is! String ||
          targetName.isEmpty ||
          hour is! int ||
          hour < 0 ||
          hour > 23 ||
          minute is! int ||
          minute < 0 ||
          minute > 59) {
        throw const FormatException('Invalid automatic backup values.');
      }
      return AutomaticBackupConfiguration(
        targetUri: targetUri,
        targetName: targetName,
        hour: hour,
        minute: minute,
        lastAttemptAt: _date(json['lastAttemptAtUtc']),
        lastSuccessAt: _date(json['lastSuccessAtUtc']),
        lastError: json['lastError'] as String?,
      );
    } on Object {
      throw const BackupException(
        'Otomatik yedekleme ayarları okunamadı. Yeniden yapılandırın.',
      );
    }
  }

  @override
  Future<String?> readPassword() => _storage.read(passwordKey);

  @override
  Future<void> save({
    required AutomaticBackupConfiguration configuration,
    required String password,
  }) async {
    await _storage.write(passwordKey, password);
    try {
      await updateConfiguration(configuration);
    } on Object {
      await _storage.delete(passwordKey);
      rethrow;
    }
  }

  @override
  Future<void> updateConfiguration(AutomaticBackupConfiguration configuration) {
    return _storage.write(
      configurationKey,
      jsonEncode({
        'version': 1,
        'targetUri': configuration.targetUri,
        'targetName': configuration.targetName,
        'hour': configuration.hour,
        'minute': configuration.minute,
        'lastAttemptAtUtc': configuration.lastAttemptAt
            ?.toUtc()
            .toIso8601String(),
        'lastSuccessAtUtc': configuration.lastSuccessAt
            ?.toUtc()
            .toIso8601String(),
        'lastError': configuration.lastError,
      }),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(configurationKey);
    await _storage.delete(passwordKey);
  }

  static DateTime? _date(Object? value) {
    return value == null ? null : DateTime.parse(value as String).toLocal();
  }
}
