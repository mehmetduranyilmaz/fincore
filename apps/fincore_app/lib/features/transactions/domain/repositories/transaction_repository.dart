import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';

export 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';

abstract interface class TransactionRepository {
  Future<List<Transaction>> getTransactions(TransactionFilter filter);

  Future<Transaction?> getById(String transactionId);

  Future<void> create(Transaction transaction);

  Future<void> createMany(List<Transaction> transactions);

  Future<void> update(Transaction transaction);
}
