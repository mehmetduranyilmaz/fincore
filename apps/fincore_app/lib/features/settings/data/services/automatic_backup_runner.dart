import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_config_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_snapshot_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_target_gateway.dart';
import 'package:fincore_app/features/settings/domain/services/backup_codec.dart';
import 'package:fincore_app/features/settings/domain/services/financial_backup_store.dart';

typedef AutomaticBackupClock = DateTime Function();

final class AutomaticBackupRunner {
  AutomaticBackupRunner(
    this._configStore,
    this._financialStore,
    this._codec,
    this._snapshotStore,
    this._targetGateway, {
    AutomaticBackupClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final AutomaticBackupConfigStore _configStore;
  final FinancialBackupStore _financialStore;
  final BackupCodec _codec;
  final AutomaticBackupSnapshotStore _snapshotStore;
  final AutomaticBackupTargetGateway _targetGateway;
  final AutomaticBackupClock _clock;

  Future<bool> run() async {
    final configuration = await _configStore.readConfiguration();
    if (configuration == null) return false;
    final password = await _configStore.readPassword();
    if (password == null || password.length < 8) {
      final now = _clock();
      await _configStore.updateConfiguration(
        configuration.withFailure(now, 'Yedek parolası bulunamadı.'),
      );
      throw const BackupException(
        'Otomatik yedek parolası bulunamadı. Yeniden yapılandırın.',
      );
    }

    final now = _clock();
    try {
      final bytes = await _codec.encrypt(
        data: await _financialStore.readFinancialData(),
        password: password,
        createdAt: now.toUtc(),
      );
      await _snapshotStore.writeLatest(bytes);
      await _targetGateway.writeLatest(configuration.targetUri, bytes);
      await _configStore.updateConfiguration(configuration.withSuccess(now));
      return true;
    } on Object catch (error) {
      await _configStore.updateConfiguration(
        configuration.withFailure(now, _safeError(error)),
      );
      rethrow;
    }
  }

  static String _safeError(Object error) {
    return error is BackupException
        ? error.message
        : 'Yedek dosyası hedef klasöre yazılamadı.';
  }
}
