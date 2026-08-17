import 'package:fincore_app/features/settings/data/services/automatic_backup_runner.dart';
import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';
import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_config_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_manager.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_scheduler.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_snapshot_store.dart';
import 'package:fincore_app/features/settings/domain/services/automatic_backup_target_gateway.dart';
import 'package:fincore_app/features/settings/domain/services/backup_codec.dart';
import 'package:fincore_app/features/settings/domain/services/financial_backup_store.dart';

final class AutomaticBackupManagerImpl implements AutomaticBackupManager {
  const AutomaticBackupManagerImpl(
    this._configStore,
    this._runner,
    this._scheduler,
    this._snapshotStore,
    this._targetGateway,
    this._codec,
    this._financialStore,
  );

  final AutomaticBackupConfigStore _configStore;
  final AutomaticBackupRunner _runner;
  final AutomaticBackupScheduler _scheduler;
  final AutomaticBackupSnapshotStore _snapshotStore;
  final AutomaticBackupTargetGateway _targetGateway;
  final BackupCodec _codec;
  final FinancialBackupStore _financialStore;

  @override
  Future<AutomaticBackupOverview> getOverview() async {
    final configuration = await _configStore.readConfiguration();
    if (configuration != null &&
        !await _targetGateway.hasWritePermission(configuration.targetUri)) {
      return AutomaticBackupOverview(
        configuration: configuration.withFailure(
          DateTime.now(),
          'Yedek klasörü izni bulunamadı. Hedefi yeniden seçin.',
        ),
        localSnapshotAvailable: await _snapshotStore.exists(),
      );
    }
    return AutomaticBackupOverview(
      configuration: configuration,
      localSnapshotAvailable: await _snapshotStore.exists(),
    );
  }

  @override
  Future<AutomaticBackupTarget?> selectTarget({String? initialUri}) {
    return _targetGateway.pickDirectory(initialUri: initialUri);
  }

  @override
  Future<void> enable({
    required AutomaticBackupTarget target,
    required String password,
    required int hour,
    required int minute,
  }) async {
    if (password.length < 8) {
      throw const BackupException('Yedek parolası en az 8 karakter olmalıdır.');
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const BackupException('Geçerli bir yedekleme saati seçin.');
    }
    if (!await _targetGateway.hasWritePermission(target.uri)) {
      throw const BackupException('Seçilen klasöre yazma izni verilemedi.');
    }

    final previous = await _configStore.readConfiguration();
    final previousPassword = await _configStore.readPassword();
    final configuration = AutomaticBackupConfiguration(
      targetUri: target.uri,
      targetName: target.name,
      hour: hour,
      minute: minute,
    );
    await _configStore.save(configuration: configuration, password: password);
    try {
      await _runner.run();
      await _scheduler.schedule(
        hour: hour,
        minute: minute,
        targetUri: target.uri,
      );
      if (previous != null && previous.targetUri != target.uri) {
        await _targetGateway.releasePermission(previous.targetUri);
      }
    } on Object {
      await _scheduler.cancel();
      if (previous != null && previousPassword != null) {
        await _configStore.save(
          configuration: previous,
          password: previousPassword,
        );
        await _scheduler.schedule(
          hour: previous.hour,
          minute: previous.minute,
          targetUri: previous.targetUri,
        );
      } else {
        await _configStore.clear();
      }
      if (previous?.targetUri != target.uri) {
        await _targetGateway.releasePermission(target.uri);
      }
      rethrow;
    }
  }

  @override
  Future<void> runNow() async {
    if (!await _runner.run()) {
      throw const BackupException('Önce otomatik yedeklemeyi yapılandırın.');
    }
  }

  @override
  Future<void> disable() async {
    final configuration = await _configStore.readConfiguration();
    await _scheduler.cancel();
    await _configStore.clear();
    if (configuration != null) {
      await _targetGateway.releasePermission(configuration.targetUri);
    }
  }

  @override
  Future<bool> restoreLocalSnapshot(String password) async {
    if (password.length < 8) {
      throw const BackupException('Yedek parolası en az 8 karakter olmalıdır.');
    }
    final bytes = await _snapshotStore.readLatest();
    if (bytes == null) return false;
    final data = await _codec.decrypt(bytes: bytes, password: password);
    await _financialStore.replaceFinancialData(data);
    return true;
  }
}
