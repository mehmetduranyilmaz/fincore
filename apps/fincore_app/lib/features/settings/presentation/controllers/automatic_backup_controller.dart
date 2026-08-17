import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/features/settings/domain/entities/automatic_backup_configuration.dart';
import 'package:fincore_app/features/settings/presentation/providers/backup_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final automaticBackupControllerProvider =
    AsyncNotifierProvider<AutomaticBackupController, AutomaticBackupOverview>(
      AutomaticBackupController.new,
    );

final class AutomaticBackupController
    extends AsyncNotifier<AutomaticBackupOverview> {
  @override
  Future<AutomaticBackupOverview> build() {
    return ref.watch(automaticBackupManagerProvider).getOverview();
  }

  Future<AutomaticBackupTarget?> selectTarget({String? initialUri}) {
    return ref
        .read(automaticBackupManagerProvider)
        .selectTarget(initialUri: initialUri);
  }

  Future<bool> enable({
    required AutomaticBackupTarget target,
    required String password,
    required int hour,
    required int minute,
  }) async {
    return _execute(
      () => ref
          .read(automaticBackupManagerProvider)
          .enable(
            target: target,
            password: password,
            hour: hour,
            minute: minute,
          ),
    );
  }

  Future<bool> runNow() {
    return _execute(() => ref.read(automaticBackupManagerProvider).runNow());
  }

  Future<bool> disable() {
    return _execute(() => ref.read(automaticBackupManagerProvider).disable());
  }

  Future<bool> restoreLocalSnapshot(String password) async {
    state = const AsyncLoading();
    try {
      final restored = await ref
          .read(automaticBackupManagerProvider)
          .restoreLocalSnapshot(password);
      if (restored) {
        await ref.read(appDataRefreshCoordinatorProvider).allDataRestored();
      }
      state = AsyncData(
        await ref.read(automaticBackupManagerProvider).getOverview(),
      );
      return restored;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<bool> _execute(Future<void> Function() action) async {
    state = const AsyncLoading();
    try {
      await action();
      state = AsyncData(
        await ref.read(automaticBackupManagerProvider).getOverview(),
      );
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
