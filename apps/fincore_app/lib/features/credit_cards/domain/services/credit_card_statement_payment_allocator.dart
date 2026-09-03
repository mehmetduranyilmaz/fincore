import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';

abstract final class CreditCardStatementPaymentAllocator {
  static Map<String, double> allocate({
    required List<CreditCardStatement> statements,
    required List<Transaction> transactions,
  }) {
    final orderedStatements = [
      ...statements,
    ]..sort((left, right) => left.statementDate.compareTo(right.statementDate));
    final paidByStatement = <String, double>{
      for (final statement in orderedStatements) statement.id: 0,
    };
    final creditCardIds = orderedStatements
        .map((statement) => statement.creditCardId)
        .toSet();
    final payments =
        transactions
            .where(
              (item) =>
                  !item.isDeleted &&
                  item.isCreditCardDebtPayment &&
                  creditCardIds.contains(item.creditCardId),
            )
            .toList()
          ..sort((left, right) {
            final date = left.transactionDate.compareTo(right.transactionDate);
            return date != 0
                ? date
                : _createdOrder(left.id).compareTo(_createdOrder(right.id));
          });

    for (final payment in payments.where(
      (item) => item.creditCardStatementId != null,
    )) {
      final statementId = payment.creditCardStatementId!;
      if (paidByStatement.containsKey(statementId)) {
        paidByStatement[statementId] =
            paidByStatement[statementId]! + payment.amount.abs();
      }
    }

    for (final payment in payments.where(
      (item) => item.creditCardStatementId == null,
    )) {
      var remainingPayment = payment.amount.abs();
      for (final statement in orderedStatements) {
        final outstanding =
            (statement.totalAmount - paidByStatement[statement.id]!).clamp(
              0.0,
              double.infinity,
            );
        if (outstanding <= 0) continue;
        final allocated = remainingPayment < outstanding
            ? remainingPayment
            : outstanding;
        paidByStatement[statement.id] =
            paidByStatement[statement.id]! + allocated;
        remainingPayment -= allocated;
        if (remainingPayment <= 0.005) break;
      }
    }
    return paidByStatement;
  }

  static int _createdOrder(String id) {
    final match = RegExp(r'\d{13,}').firstMatch(id);
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }
}
