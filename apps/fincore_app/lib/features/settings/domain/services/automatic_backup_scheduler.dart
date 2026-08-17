abstract interface class AutomaticBackupScheduler {
  Future<void> schedule({
    required int hour,
    required int minute,
    required String targetUri,
  });

  Future<void> cancel();
}
