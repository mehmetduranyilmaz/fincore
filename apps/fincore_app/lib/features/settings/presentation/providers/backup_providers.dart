import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/settings/data/services/automatic_backup_manager_impl.dart';
import 'package:fincore_app/features/settings/data/services/automatic_backup_runner.dart';
import 'package:fincore_app/features/settings/data/services/encrypted_backup_codec.dart';
import 'package:fincore_app/features/settings/data/services/backup_key_value_store.dart';
import 'package:fincore_app/features/settings/data/services/file_automatic_backup_snapshot_store.dart';
import 'package:fincore_app/features/settings/data/services/platform_backup_file_gateway.dart';
import 'package:fincore_app/features/settings/data/services/saf_automatic_backup_target_gateway.dart';
import 'package:fincore_app/features/settings/data/services/secure_storage_automatic_backup_config_store.dart';
import 'package:fincore_app/features/settings/data/services/secure_storage_financial_backup_store.dart';
import 'package:fincore_app/features/settings/data/services/workmanager_automatic_backup_scheduler.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_config_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_manager.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_scheduler.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_snapshot_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_target_gateway.dart';
import 'package:fincore_app/features/settings/domain/services/backup_codec.dart';
import 'package:fincore_app/features/settings/domain/services/backup_file_gateway.dart';
import 'package:fincore_app/features/settings/domain/services/financial_backup_store.dart';
import 'package:fincore_app/features/settings/domain/usecases/create_financial_backup.dart';
import 'package:fincore_app/features/settings/domain/usecases/restore_financial_backup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupKeyValueStoreProvider = Provider<BackupKeyValueStore>(
  (ref) => SecureBackupKeyValueStore(ref.watch(secureStorageServiceProvider)),
);

final financialBackupStoreProvider = Provider<FinancialBackupStore>(
  (ref) =>
      SecureStorageFinancialBackupStore(ref.watch(backupKeyValueStoreProvider)),
);

final backupCodecProvider = Provider<BackupCodec>(
  (ref) => EncryptedBackupCodec(),
);

final backupFileGatewayProvider = Provider<BackupFileGateway>(
  (ref) => const PlatformBackupFileGateway(),
);

final createFinancialBackupProvider = Provider<CreateFinancialBackupUseCase>(
  (ref) => CreateFinancialBackupUseCase(
    ref.watch(financialBackupStoreProvider),
    ref.watch(backupCodecProvider),
    ref.watch(backupFileGatewayProvider),
  ),
);

final restoreFinancialBackupProvider = Provider<RestoreFinancialBackupUseCase>(
  (ref) => RestoreFinancialBackupUseCase(
    ref.watch(financialBackupStoreProvider),
    ref.watch(backupCodecProvider),
    ref.watch(backupFileGatewayProvider),
  ),
);

final automaticBackupConfigStoreProvider = Provider<AutomaticBackupConfigStore>(
  (ref) => SecureStorageAutomaticBackupConfigStore(
    ref.watch(backupKeyValueStoreProvider),
  ),
);

final automaticBackupSnapshotStoreProvider =
    Provider<AutomaticBackupSnapshotStore>(
      (ref) => FileAutomaticBackupSnapshotStore(),
    );

final automaticBackupTargetGatewayProvider =
    Provider<AutomaticBackupTargetGateway>(
      (ref) => SafAutomaticBackupTargetGateway(),
    );

final automaticBackupSchedulerProvider = Provider<AutomaticBackupScheduler>(
  (ref) => WorkmanagerAutomaticBackupScheduler(),
);

final automaticBackupRunnerProvider = Provider<AutomaticBackupRunner>(
  (ref) => AutomaticBackupRunner(
    ref.watch(automaticBackupConfigStoreProvider),
    ref.watch(financialBackupStoreProvider),
    ref.watch(backupCodecProvider),
    ref.watch(automaticBackupSnapshotStoreProvider),
    ref.watch(automaticBackupTargetGatewayProvider),
  ),
);

final automaticBackupManagerProvider = Provider<AutomaticBackupManager>(
  (ref) => AutomaticBackupManagerImpl(
    ref.watch(automaticBackupConfigStoreProvider),
    ref.watch(automaticBackupRunnerProvider),
    ref.watch(automaticBackupSchedulerProvider),
    ref.watch(automaticBackupSnapshotStoreProvider),
    ref.watch(automaticBackupTargetGatewayProvider),
    ref.watch(backupCodecProvider),
    ref.watch(financialBackupStoreProvider),
  ),
);
