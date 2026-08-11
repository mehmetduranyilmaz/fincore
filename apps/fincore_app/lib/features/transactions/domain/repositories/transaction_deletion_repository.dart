abstract interface class TransactionDeletionRepository {
  Future<void> deleteMany(Set<String> transactionIds);
}
