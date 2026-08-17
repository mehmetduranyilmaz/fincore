abstract interface class AutomaticBackupSnapshotStore {
  Future<void> writeLatest(List<int> bytes);

  Future<List<int>?> readLatest();

  Future<bool> exists();
}
