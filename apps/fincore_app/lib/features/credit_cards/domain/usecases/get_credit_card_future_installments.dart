import 'package:fincore_app/core/utils/turkish_text.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

typedef CreditCardFutureInstallmentClock = DateTime Function();

final class GetCreditCardFutureInstallmentsUseCase {
  GetCreditCardFutureInstallmentsUseCase(
    this._transactionRepository,
    this._statementRepository, {
    CreditCardFutureInstallmentClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final TransactionRepository _transactionRepository;
  final CreditCardStatementRepository _statementRepository;
  final CreditCardFutureInstallmentClock _clock;

  Future<List<Transaction>> execute(CreditCard creditCard) async {
    final now = _dateOnly(_clock());
    final statements = await _statementRepository.getByCreditCardId(
      creditCard.id,
    );
    final assignedIds = statements
        .expand((statement) => statement.lines)
        .map((line) => line.transactionId)
        .toSet();
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(creditCardId: creditCard.id),
    );
    final result = transactions.where((transaction) {
      return transaction.creditCardId == creditCard.id &&
          !transaction.isDeleted &&
          transaction.paymentGroupId == null &&
          transaction.transactionType == TransactionType.expense &&
          transaction.isInstallment &&
          transaction.transactionDate.isAfter(now) &&
          !assignedIds.contains(transaction.id);
    }).toList();
    result.sort(_compare);
    return List.unmodifiable(result);
  }

  static int _compare(Transaction left, Transaction right) {
    final dateComparison = left.transactionDate.compareTo(
      right.transactionDate,
    );
    if (dateComparison != 0) return dateComparison;
    final descriptionComparison = TurkishText.compare(
      left.merchant,
      right.merchant,
    );
    if (descriptionComparison != 0) return descriptionComparison;
    final installmentComparison = (left.installmentNumber ?? 0).compareTo(
      right.installmentNumber ?? 0,
    );
    if (installmentComparison != 0) return installmentComparison;
    return left.id.compareTo(right.id);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
