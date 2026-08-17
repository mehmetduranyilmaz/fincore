final class AutomaticBackupConfiguration {
  const AutomaticBackupConfiguration({
    required this.targetUri,
    required this.targetName,
    required this.hour,
    required this.minute,
    this.lastAttemptAt,
    this.lastSuccessAt,
    this.lastError,
  }) : assert(hour >= 0 && hour <= 23),
       assert(minute >= 0 && minute <= 59);

  final String targetUri;
  final String targetName;
  final int hour;
  final int minute;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
  final String? lastError;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  AutomaticBackupConfiguration withSuccess(DateTime value) {
    return AutomaticBackupConfiguration(
      targetUri: targetUri,
      targetName: targetName,
      hour: hour,
      minute: minute,
      lastAttemptAt: value,
      lastSuccessAt: value,
    );
  }

  AutomaticBackupConfiguration withFailure(DateTime value, String error) {
    return AutomaticBackupConfiguration(
      targetUri: targetUri,
      targetName: targetName,
      hour: hour,
      minute: minute,
      lastAttemptAt: value,
      lastSuccessAt: lastSuccessAt,
      lastError: error,
    );
  }
}

final class AutomaticBackupOverview {
  const AutomaticBackupOverview({
    required this.configuration,
    required this.localSnapshotAvailable,
  });

  final AutomaticBackupConfiguration? configuration;
  final bool localSnapshotAvailable;

  bool get isEnabled => configuration != null;
}

final class AutomaticBackupTarget {
  const AutomaticBackupTarget({required this.uri, required this.name});

  final String uri;
  final String name;
}
