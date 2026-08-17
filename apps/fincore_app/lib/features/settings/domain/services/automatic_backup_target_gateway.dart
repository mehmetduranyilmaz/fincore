import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';

abstract interface class AutomaticBackupTargetGateway {
  Future<AutomaticBackupTarget?> pickDirectory({String? initialUri});

  Future<bool> hasWritePermission(String uri);

  Future<void> writeLatest(String directoryUri, List<int> bytes);

  Future<void> releasePermission(String uri);
}
