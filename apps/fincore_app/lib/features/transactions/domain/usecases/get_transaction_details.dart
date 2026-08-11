import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class GetTransactionDetailsUseCase {
  const GetTransactionDetailsUseCase(this._repository);

  final TransactionRepository _repository;

  Future<Transaction?> execute(String transactionId) {
    if (transactionId.trim().isEmpty) {
      throw ArgumentError.value(transactionId, 'transactionId');
    }
    return _repository.getById(transactionId);
  }
}
