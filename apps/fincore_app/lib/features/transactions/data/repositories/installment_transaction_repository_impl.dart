import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/installment_transaction_repository.dart';

final class InstallmentTransactionRepositoryImpl
    implements InstallmentTransactionRepository {
  const InstallmentTransactionRepositoryImpl(this._dataSource);

  final InstallmentTransactionDataSource _dataSource;

  @override
  Future<void> createPlan(List<Transaction> installments) {
    return _dataSource.insertPlan(installments);
  }

  @override
  Future<void> replaceWithPlan(List<Transaction> installments) {
    return _dataSource.replaceWithPlan(installments);
  }
}
