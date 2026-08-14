import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';

final class CreditCardStatementPaymentStatus {
  const CreditCardStatementPaymentStatus({
    required this.statement,
    required this.paidAmount,
  });

  final CreditCardStatement statement;
  final double paidAmount;

  double get remainingAmount {
    final remaining = statement.totalAmount - paidAmount;
    return remaining > 0 ? remaining : 0;
  }

  bool get isPaid => remainingAmount <= 0.005;
}
