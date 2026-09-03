import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/services/credit_card_statement_payment_allocator.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

typedef CreditCardBalanceClock = DateTime Function();

final class CalculateCreditCardBalanceUseCase {
  CalculateCreditCardBalanceUseCase(
    this._creditCardRepository,
    this._transactionRepository, {
    this._statementRepository,
    CreditCardBalanceClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final CreditCardRepository _creditCardRepository;
  final TransactionRepository _transactionRepository;
  final CreditCardStatementRepository? _statementRepository;
  final CreditCardBalanceClock _clock;

  Future<CreditCardBalance> execute(String creditCardId) async {
    if (creditCardId.trim().isEmpty) {
      throw ArgumentError.value(creditCardId, 'creditCardId');
    }

    final creditCards = await _creditCardRepository.getCreditCards();
    final creditCard = _findCreditCard(creditCards, creditCardId);
    if (creditCard == null) {
      throw StateError('Credit card not found.');
    }

    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(creditCardId: creditCardId),
    );
    var availableLimitUsed = 0.0;
    var totalSpent = 0.0;
    var totalPayments = 0.0;

    for (final transaction in transactions) {
      if (transaction.isDeleted || transaction.creditCardId != creditCardId) {
        continue;
      }

      switch (transaction.transactionType) {
        case TransactionType.expense:
          final amount = transaction.amount.abs();
          availableLimitUsed += amount;
          totalSpent += amount;
        case TransactionType.income:
          final amount = transaction.amount.abs();
          availableLimitUsed -= amount;
          totalPayments += amount;
        case TransactionType.transfer:
          continue;
      }
    }

    // Keep the use case usable with its legacy two-repository construction in
    // isolated callers. Production injects the statement repository below.
    if (_statementRepository == null) {
      return CreditCardBalance(
        creditLimit: creditCard.creditLimit,
        currentDebt: availableLimitUsed,
        availableLimitUsed: availableLimitUsed,
        totalSpent: totalSpent,
        totalPayments: totalPayments,
      );
    }

    final statements = await _statementRepository.getByCreditCardId(
      creditCardId,
    );
    final assignedIds = statements
        .expand((statement) => statement.lines)
        .map((line) => line.transactionId)
        .toSet();
    var currentDebt = 0.0;
    final paidByStatement = CreditCardStatementPaymentAllocator.allocate(
      statements: statements,
      transactions: transactions,
    );
    for (final statement in statements) {
      final paid = paidByStatement[statement.id] ?? 0.0;
      currentDebt += (statement.totalAmount - paid).clamp(0.0, double.infinity);
    }
    final now = _clock();
    for (final transaction in transactions) {
      if (transaction.isDeleted ||
          transaction.creditCardId != creditCardId ||
          assignedIds.contains(transaction.id) ||
          transaction.isCreditCardDebtPayment ||
          transaction.transactionDate.isAfter(now)) {
        continue;
      }
      switch (transaction.transactionType) {
        case TransactionType.expense:
          currentDebt += transaction.amount.abs();
        case TransactionType.income:
          currentDebt -= transaction.amount.abs();
        case TransactionType.transfer:
          continue;
      }
    }

    return CreditCardBalance(
      creditLimit: creditCard.creditLimit,
      currentDebt: currentDebt,
      availableLimitUsed: availableLimitUsed,
      totalSpent: totalSpent,
      totalPayments: totalPayments,
    );
  }

  CreditCard? _findCreditCard(
    List<CreditCard> creditCards,
    String creditCardId,
  ) {
    for (final creditCard in creditCards) {
      if (creditCard.id == creditCardId) {
        return creditCard;
      }
    }
    return null;
  }
}
