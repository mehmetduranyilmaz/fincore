import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

typedef CreditCardCurrentPeriodClock = DateTime Function();

final class GetCreditCardCurrentPeriodTransactionsUseCase {
  GetCreditCardCurrentPeriodTransactionsUseCase(
    this._transactionRepository,
    this._statementRepository, {
    CreditCardCurrentPeriodClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final TransactionRepository _transactionRepository;
  final CreditCardStatementRepository _statementRepository;
  final CreditCardCurrentPeriodClock _clock;

  Future<List<Transaction>> execute(String creditCardId) async {
    if (creditCardId.trim().isEmpty) {
      throw ArgumentError.value(creditCardId, 'creditCardId');
    }
    final now = _clock();
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
    final result = transactions.where((transaction) {
      return transaction.creditCardId == creditCardId &&
          !transaction.isDeleted &&
          transaction.paymentGroupId == null &&
          transaction.transactionType != TransactionType.transfer &&
          !transaction.transactionDate.isAfter(now) &&
          !assignedIds.contains(transaction.id);
    }).toList();
    result.sort(
      (left, right) => right.transactionDate.compareTo(left.transactionDate),
    );
    return List.unmodifiable(result);
  }
}
