import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_deletion_repository.dart';

final class DeleteTransactionUseCase {
  const DeleteTransactionUseCase(this._repository, this._deletionRepository);

  final TransactionRepository _repository;
  final TransactionDeletionRepository _deletionRepository;

  Future<List<Transaction>> execute(String transactionId) async {
    if (transactionId.trim().isEmpty) {
      throw ArgumentError.value(transactionId, 'transactionId');
    }

    final transaction = await _repository.getById(transactionId);
    if (transaction == null) {
      throw StateError('Transaction not found.');
    }
    if (!transaction.isDeletable) {
      throw StateError('Transaction cannot be deleted.');
    }

    final transactions = await _repository.getTransactions(TransactionFilter());
    final related = transactions.where((item) {
      if (transaction.installmentPlanId != null) {
        return item.installmentPlanId == transaction.installmentPlanId;
      }
      if (transaction.transferGroupId != null) {
        return item.transferGroupId == transaction.transferGroupId;
      }
      if (transaction.paymentGroupId != null) {
        return item.paymentGroupId == transaction.paymentGroupId;
      }
      return item.id == transaction.id;
    });

    await _deletionRepository.deleteMany(
      related.map((item) => item.id).toSet(),
    );
    return List.unmodifiable(related);
  }
}
