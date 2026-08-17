import 'package:fincore_app/features/settings/data/services/workmanager_automatic_backup_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates delay until the next configured local time', () {
    expect(
      WorkmanagerAutomaticBackupScheduler.delayUntilNextRun(
        DateTime(2026, 8, 17, 1, 15),
        hour: 2,
        minute: 0,
      ),
      const Duration(minutes: 45),
    );
    expect(
      WorkmanagerAutomaticBackupScheduler.delayUntilNextRun(
        DateTime(2026, 8, 17, 2, 1),
        hour: 2,
        minute: 0,
      ),
      const Duration(hours: 23, minutes: 59),
    );
  });
}
