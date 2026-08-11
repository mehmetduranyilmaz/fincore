import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class GetTransactions {
  const GetTransactions(this._repository);

  final TransactionRepository _repository;

  Future<List<Transaction>> execute(TransactionFilter filter) async {
    final transactions = [...await _repository.getTransactions(filter)]
      ..sort(
        (left, right) => right.transactionDate.compareTo(left.transactionDate),
      );
    return List.unmodifiable(transactions);
  }
}
