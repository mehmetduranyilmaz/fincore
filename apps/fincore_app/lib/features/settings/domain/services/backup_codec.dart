abstract interface class BackupCodec {
  Future<List<int>> encrypt({
    required Map<String, String?> data,
    required String password,
    required DateTime createdAt,
  });

  Future<Map<String, String?>> decrypt({
    required List<int> bytes,
    required String password,
  });
}
