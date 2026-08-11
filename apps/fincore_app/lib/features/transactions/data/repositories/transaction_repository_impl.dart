import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_deletion_repository.dart';

final class TransactionRepositoryImpl
    implements TransactionRepository, TransactionDeletionRepository {
  const TransactionRepositoryImpl(this._dataSource);

  final TransactionDataSource _dataSource;

  @override
  Future<void> create(Transaction transaction) {
    return _dataSource.insert(transaction);
  }

  @override
  Future<void> createMany(List<Transaction> transactions) {
    return _dataSource.insertMany(transactions);
  }

  @override
  Future<Transaction?> getById(String transactionId) {
    return _dataSource.findById(transactionId);
  }

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    final transactions = await _dataSource.getTransactions(filter);
    return List.unmodifiable(transactions);
  }

  @override
  Future<void> update(Transaction transaction) {
    return _dataSource.replace(transaction);
  }

  @override
  Future<void> deleteMany(Set<String> transactionIds) {
    return _dataSource.removeMany(transactionIds);
  }
}
