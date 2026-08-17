import 'dart:ui';

import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/settings/data/services/automatic_backup_runner.dart';
import 'package:fincore_app/features/settings/data/services/backup_key_value_store.dart';
import 'package:fincore_app/features/settings/data/services/encrypted_backup_codec.dart';
import 'package:fincore_app/features/settings/data/services/file_automatic_backup_snapshot_store.dart';
import 'package:fincore_app/features/settings/data/services/saf_automatic_backup_target_gateway.dart';
import 'package:fincore_app/features/settings/data/services/secure_storage_automatic_backup_config_store.dart';
import 'package:fincore_app/features/settings/data/services/secure_storage_financial_backup_store.dart';
import 'package:fincore_app/features/settings/data/services/workmanager_automatic_backup_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

Future<void> initializeAutomaticBackupBackground() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  await Workmanager().initialize(automaticBackupCallbackDispatcher);
}

@pragma('vm:entry-point')
void automaticBackupCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != WorkmanagerAutomaticBackupScheduler.taskName) return true;
    DartPluginRegistrant.ensureInitialized();
    try {
      const secureStorage = FlutterSecureStorage();
      final keyValueStore = SecureBackupKeyValueStore(
        const SecureStorageService(secureStorage),
      );
      final configStore = SecureStorageAutomaticBackupConfigStore(
        keyValueStore,
      );
      final runner = AutomaticBackupRunner(
        configStore,
        SecureStorageFinancialBackupStore(keyValueStore),
        EncryptedBackupCodec(),
        FileAutomaticBackupSnapshotStore(),
        SafAutomaticBackupTargetGateway(),
      );
      await runner.run();
      return true;
    } on Object {
      return false;
    }
  });
}
