import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/settings/data/services/encrypted_backup_codec.dart';
import 'package:fincore_app/features/settings/data/services/backup_key_value_store.dart';
import 'package:fincore_app/features/settings/data/services/platform_backup_file_gateway.dart';
import 'package:fincore_app/features/settings/data/services/secure_storage_financial_backup_store.dart';
import 'package:fincore_app/features/settings/domain/services/backup_codec.dart';
import 'package:fincore_app/features/settings/domain/services/backup_file_gateway.dart';
import 'package:fincore_app/features/settings/domain/services/financial_backup_store.dart';
import 'package:fincore_app/features/settings/domain/usecases/create_financial_backup.dart';
import 'package:fincore_app/features/settings/domain/usecases/restore_financial_backup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final financialBackupStoreProvider = Provider<FinancialBackupStore>(
  (ref) => SecureStorageFinancialBackupStore(
    SecureBackupKeyValueStore(ref.watch(secureStorageServiceProvider)),
  ),
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
