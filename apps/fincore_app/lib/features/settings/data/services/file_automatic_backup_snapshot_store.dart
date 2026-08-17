import 'dart:io';

import 'package:fincore_app/features/settings/domain/services/automatic_backup_snapshot_store.dart';
import 'package:path_provider/path_provider.dart';

typedef AutomaticBackupDirectoryProvider = Future<Directory> Function();

final class FileAutomaticBackupSnapshotStore
    implements AutomaticBackupSnapshotStore {
  FileAutomaticBackupSnapshotStore({
    AutomaticBackupDirectoryProvider? directoryProvider,
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const String directoryName = 'automatic_backup';
  static const String fileName = 'hesabim-son-yedek.fincorebackup';

  final AutomaticBackupDirectoryProvider _directoryProvider;

  @override
  Future<bool> exists() async => (await _latestFile()).exists();

  @override
  Future<List<int>?> readLatest() async {
    final latest = await _latestFile();
    if (await latest.exists()) return latest.readAsBytes();
    final previous = File('${latest.path}.previous');
    return await previous.exists() ? previous.readAsBytes() : null;
  }

  @override
  Future<void> writeLatest(List<int> bytes) async {
    final latest = await _latestFile(createDirectory: true);
    final temporary = File('${latest.path}.temporary');
    final previous = File('${latest.path}.previous');
    await temporary.writeAsBytes(bytes, flush: true);
    if (await previous.exists()) await previous.delete();
    if (await latest.exists()) await latest.rename(previous.path);
    try {
      await temporary.rename(latest.path);
      if (await previous.exists()) await previous.delete();
    } on Object {
      if (!await latest.exists() && await previous.exists()) {
        await previous.rename(latest.path);
      }
      rethrow;
    }
  }

  Future<File> _latestFile({bool createDirectory = false}) async {
    final root = await _directoryProvider();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}$directoryName',
    );
    if (createDirectory && !await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }
}
