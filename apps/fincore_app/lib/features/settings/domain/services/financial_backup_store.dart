abstract interface class FinancialBackupStore {
  Future<Map<String, String?>> readFinancialData();

  Future<void> replaceFinancialData(Map<String, String?> data);
}
