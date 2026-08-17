import 'dart:typed_data';

import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';
import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_target_gateway.dart';
import 'package:saf/saf.dart';

final class SafAutomaticBackupTargetGateway
    implements AutomaticBackupTargetGateway {
  SafAutomaticBackupTargetGateway({Saf? saf}) : _saf = saf ?? Saf();

  static const String fileName = 'hesabim-son-yedek.fincorebackup';
  static const String mimeType = 'application/json';

  final Saf _saf;

  @override
  Future<AutomaticBackupTarget?> pickDirectory({String? initialUri}) async {
    final directory = await _saf.pickDirectory(initialUri: initialUri);
    if (directory == null) return null;
    return AutomaticBackupTarget(uri: directory.uri, name: directory.name);
  }

  @override
  Future<bool> hasWritePermission(String uri) async {
    final permissions = await _saf.persistedPermissions();
    return permissions.any(
      (permission) => permission.uri == uri && permission.write,
    );
  }

  @override
  Future<void> writeLatest(String directoryUri, List<int> bytes) async {
    if (!await hasWritePermission(directoryUri)) {
      throw const BackupException(
        'Yedek klasörü izni bulunamadı. Hedef klasörü yeniden seçin.',
      );
    }
    await _saf.writeFileBytes(
      directoryUri,
      fileName,
      mimeType,
      Uint8List.fromList(bytes),
      overwrite: true,
    );
  }

  @override
  Future<void> releasePermission(String uri) async {
    if (await hasWritePermission(uri)) {
      await _saf.releasePersistedPermission(uri);
    }
  }
}
