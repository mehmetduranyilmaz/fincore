import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class CalculateCreditCardBalanceUseCase {
  const CalculateCreditCardBalanceUseCase(
    this._creditCardRepository,
    this._transactionRepository,
  );

  final CreditCardRepository _creditCardRepository;
  final TransactionRepository _transactionRepository;

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
    var currentDebt = 0.0;
    var totalSpent = 0.0;
    var totalPayments = 0.0;

    for (final transaction in transactions) {
      if (transaction.isDeleted || transaction.creditCardId != creditCardId) {
        continue;
      }

      switch (transaction.transactionType) {
        case TransactionType.expense:
          final amount = transaction.amount.abs();
          currentDebt += amount;
          totalSpent += amount;
        case TransactionType.income:
          final amount = transaction.amount.abs();
          currentDebt -= amount;
          totalPayments += amount;
        case TransactionType.transfer:
          continue;
      }
    }

    return CreditCardBalance(
      creditLimit: creditCard.creditLimit,
      currentDebt: currentDebt,
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
