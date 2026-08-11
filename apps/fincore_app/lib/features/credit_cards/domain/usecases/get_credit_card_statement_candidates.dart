import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class GetCreditCardStatementCandidatesUseCase {
  const GetCreditCardStatementCandidatesUseCase(
    this._statementRepository,
    this._transactionRepository,
  );

  final CreditCardStatementRepository _statementRepository;
  final TransactionRepository _transactionRepository;

  Future<List<Transaction>> execute({
    required String creditCardId,
    required DateTime statementDate,
  }) async {
    if (creditCardId.trim().isEmpty) {
      throw ArgumentError.value(creditCardId, 'creditCardId');
    }
    final cutoffExclusive = DateTime(
      statementDate.year,
      statementDate.month,
      statementDate.day + 1,
    );
    final statements = await _statementRepository.getByCreditCardId(
      creditCardId,
    );
    final assignedIds = statements
        .expand((statement) => statement.lines)
        .map((line) => line.transactionId)
        .toSet();
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(creditCardId: creditCardId),
    );
    final candidates = transactions.where((transaction) {
      return transaction.creditCardId == creditCardId &&
          !transaction.isDeleted &&
          transaction.paymentGroupId == null &&
          transaction.transactionType != TransactionType.transfer &&
          transaction.transactionDate.isBefore(cutoffExclusive) &&
          !assignedIds.contains(transaction.id);
    }).toList();
    candidates.sort(
      (left, right) => right.transactionDate.compareTo(left.transactionDate),
    );
    return List.unmodifiable(candidates);
  }
}
