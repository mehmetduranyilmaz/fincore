abstract interface class CreditCardUsageRepository {
  Future<bool> hasUsage(String creditCardId);
}
