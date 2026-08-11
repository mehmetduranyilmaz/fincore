abstract interface class AccountUsageRepository {
  Future<bool> hasUsage(String accountId);
}
