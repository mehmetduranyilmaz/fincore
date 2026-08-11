abstract interface class CustomerUsageRepository {
  Future<bool> hasUsage(String customerId);
}
