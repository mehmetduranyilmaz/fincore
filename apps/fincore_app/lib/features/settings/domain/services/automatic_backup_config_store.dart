import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';

abstract interface class AutomaticBackupConfigStore {
  Future<AutomaticBackupConfiguration?> readConfiguration();

  Future<String?> readPassword();

  Future<void> save({
    required AutomaticBackupConfiguration configuration,
    required String password,
  });

  Future<void> updateConfiguration(AutomaticBackupConfiguration configuration);

  Future<void> clear();
}
