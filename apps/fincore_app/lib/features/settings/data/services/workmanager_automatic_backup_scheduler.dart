import 'package:fincore_app/features/settings/domain/services/automatic_backup_scheduler.dart';
import 'package:workmanager/workmanager.dart';

typedef SchedulerClock = DateTime Function();

final class WorkmanagerAutomaticBackupScheduler
    implements AutomaticBackupScheduler {
  WorkmanagerAutomaticBackupScheduler({
    Workmanager? workmanager,
    SchedulerClock? clock,
  }) : _workmanager = workmanager ?? Workmanager(),
       _clock = clock ?? DateTime.now;

  static const String uniqueName = 'hesabim-daily-automatic-backup-v1';
  static const String taskName = 'hesabimAutomaticBackup';
  static const String tag = 'hesabim-automatic-backup';

  final Workmanager _workmanager;
  final SchedulerClock _clock;

  @override
  Future<void> schedule({
    required int hour,
    required int minute,
    required String targetUri,
  }) async {
    await _workmanager.cancelByUniqueName(uniqueName);
    await _workmanager.registerPeriodicTask(
      uniqueName,
      taskName,
      frequency: const Duration(hours: 24),
      initialDelay: delayUntilNextRun(_clock(), hour: hour, minute: minute),
      constraints: Constraints(
        networkType: _requiresNetwork(targetUri)
            ? NetworkType.connected
            : NetworkType.notRequired,
        requiresBatteryNotLow: true,
        requiresStorageNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
      tag: tag,
    );
  }

  @override
  Future<void> cancel() => _workmanager.cancelByUniqueName(uniqueName);

  static Duration delayUntilNextRun(
    DateTime now, {
    required int hour,
    required int minute,
  }) {
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next.difference(now);
  }

  static bool _requiresNetwork(String uri) {
    return !uri.contains('com.android.externalstorage.documents') &&
        !uri.contains('com.android.providers.downloads.documents') &&
        !uri.contains('com.android.providers.media.documents');
  }
}
