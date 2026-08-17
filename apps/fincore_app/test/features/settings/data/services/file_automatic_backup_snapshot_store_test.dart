import 'dart:io';

import 'package:fincore_app/features/settings/data/services/file_automatic_backup_snapshot_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('atomically replaces the single latest snapshot', () async {
    final directory = await Directory.systemTemp.createTemp(
      'fincore-auto-backup-test-',
    );
    addTearDown(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final store = FileAutomaticBackupSnapshotStore(
      directoryProvider: () async => directory,
    );

    await store.writeLatest([1, 2, 3]);
    await store.writeLatest([4, 5]);

    expect(await store.exists(), isTrue);
    expect(await store.readLatest(), [4, 5]);
    final backupDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}'
      '${FileAutomaticBackupSnapshotStore.directoryName}',
    );
    expect(await backupDirectory.list().map((file) => file.path).toList(), [
      '${backupDirectory.path}${Platform.pathSeparator}'
          '${FileAutomaticBackupSnapshotStore.fileName}',
    ]);
  });
}
