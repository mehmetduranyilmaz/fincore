abstract interface class BackupFileGateway {
  Future<void> share({required String fileName, required List<int> bytes});

  Future<List<int>?> pick();
}
