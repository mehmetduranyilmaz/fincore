abstract interface class CategoryUsageRepository {
  Future<bool> hasUsage(String categoryId);
}
