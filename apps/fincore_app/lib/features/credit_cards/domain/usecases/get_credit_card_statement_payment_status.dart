import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement_payment_status.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class GetCreditCardStatementPaymentStatusUseCase {
  const GetCreditCardStatementPaymentStatusUseCase(
    this._statementRepository,
    this._transactionRepository,
  );

  final CreditCardStatementRepository _statementRepository;
  final TransactionRepository _transactionRepository;

  Future<CreditCardStatementPaymentStatus> execute({
    required String creditCardId,
    required String statementId,
  }) async {
    if (creditCardId.trim().isEmpty || statementId.trim().isEmpty) {
      throw ArgumentError('Credit card and statement are required.');
    }
    final statements = await _statementRepository.getByCreditCardId(
      creditCardId,
    );
    final statement = statements
        .where((item) => item.id == statementId)
        .firstOrNull;
    if (statement == null) {
      throw StateError('Credit card statement not found.');
    }
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(creditCardId: creditCardId),
    );
    final paidAmount = transactions
        .where(
          (transaction) =>
              !transaction.isDeleted &&
              transaction.isCreditCardDebtPayment &&
              transaction.creditCardStatementId == statementId,
        )
        .fold(0.0, (total, transaction) => total + transaction.amount.abs());
    return CreditCardStatementPaymentStatus(
      statement: statement,
      paidAmount: paidAmount,
    );
  }
}
