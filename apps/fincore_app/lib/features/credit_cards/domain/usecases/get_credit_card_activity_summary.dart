import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_activity_summary.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/services/credit_card_period_calculator.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

typedef CreditCardActivityClock = DateTime Function();

final class GetCreditCardActivitySummaryUseCase {
  GetCreditCardActivitySummaryUseCase(
    this._repository, {
    required this._statementRepository,
    CreditCardActivityClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final TransactionRepository _repository;
  final CreditCardStatementRepository _statementRepository;
  final CreditCardActivityClock _clock;

  Future<CreditCardActivitySummary> execute(CreditCard creditCard) async {
    final now = _dateOnly(_clock());
    final upcomingCutoff = CreditCardPeriodCalculator.upcomingStatementDate(
      referenceDate: now,
      statementDay: creditCard.statementDay,
    );
    final transactions = await _repository.getTransactions(
      TransactionFilter(creditCardId: creditCard.id),
    );
    final statements = [
      ...await _statementRepository.getByCreditCardId(creditCard.id),
    ];
    statements.sort(
      (left, right) => right.statementDate.compareTo(left.statementDate),
    );
    final assignedIds = statements
        .expand((statement) => statement.lines)
        .map((line) => line.transactionId)
        .toSet();

    final statementAmount = statements.isEmpty
        ? 0.0
        : statements.first.totalAmount;
    var currentPeriodAmount = 0.0;
    var futureInstallmentAmount = 0.0;
    for (final transaction in transactions) {
      if (transaction.isDeleted || transaction.creditCardId != creditCard.id) {
        continue;
      }
      final signedAmount = _signedAmount(transaction);
      if (!transaction.isCreditCardDebtPayment &&
          !assignedIds.contains(transaction.id) &&
          !transaction.transactionDate.isAfter(now)) {
        currentPeriodAmount += signedAmount;
      }
      if (transaction.isInstallment &&
          transaction.paymentGroupId == null &&
          transaction.transactionType == TransactionType.expense &&
          transaction.transactionDate.isAfter(upcomingCutoff) &&
          !assignedIds.contains(transaction.id)) {
        futureInstallmentAmount += transaction.amount.abs();
      }
    }

    return CreditCardActivitySummary(
      statementAmount: statementAmount,
      currentPeriodAmount: currentPeriodAmount,
      futureInstallmentAmount: futureInstallmentAmount,
    );
  }

  static double _signedAmount(Transaction transaction) {
    return switch (transaction.transactionType) {
      TransactionType.expense => transaction.amount.abs(),
      TransactionType.income => -transaction.amount.abs(),
      TransactionType.transfer => 0,
    };
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
