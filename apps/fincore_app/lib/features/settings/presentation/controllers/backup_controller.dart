import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:fincore_app/features/settings/presentation/providers/backup_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BackupOperation { idle, creating, restoring }

final class BackupState {
  const BackupState({
    this.operation = BackupOperation.idle,
    this.message,
    this.isError = false,
  });

  final BackupOperation operation;
  final String? message;
  final bool isError;

  bool get isBusy => operation != BackupOperation.idle;
}

final backupControllerProvider =
    NotifierProvider<BackupController, BackupState>(BackupController.new);

final class BackupController extends Notifier<BackupState> {
  @override
  BackupState build() => const BackupState();

  Future<void> create(String password) async {
    state = const BackupState(operation: BackupOperation.creating);
    try {
      final fileName = await ref
          .read(createFinancialBackupProvider)
          .execute(password);
      state = BackupState(
        message: '$fileName oluşturuldu. Dosyayı güvenli bir konuma kaydedin.',
      );
    } on Object catch (error) {
      state = BackupState(message: _message(error), isError: true);
    }
  }

  Future<bool> restore(String password) async {
    state = const BackupState(operation: BackupOperation.restoring);
    try {
      final restored = await ref
          .read(restoreFinancialBackupProvider)
          .execute(password);
      if (!restored) {
        state = const BackupState();
        return false;
      }
      await ref.read(appDataRefreshCoordinatorProvider).allDataRestored();
      state = const BackupState(
        message: 'Finansal kayıtlar başarıyla geri yüklendi.',
      );
      return true;
    } on Object catch (error) {
      state = BackupState(message: _message(error), isError: true);
      return false;
    }
  }

  void clearMessage() => state = const BackupState();

  static String _message(Object error) {
    return error is BackupException ? error.message : ErrorMapper.map(error);
  }
}
