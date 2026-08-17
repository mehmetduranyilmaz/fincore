import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';

abstract interface class AutomaticBackupManager {
  Future<AutomaticBackupOverview> getOverview();

  Future<AutomaticBackupTarget?> selectTarget({String? initialUri});

  Future<void> enable({
    required AutomaticBackupTarget target,
    required String password,
    required int hour,
    required int minute,
  });

  Future<void> runNow();

  Future<void> disable();

  Future<bool> restoreLocalSnapshot(String password);
}
