final class CreditCardPaymentInput {
  const CreditCardPaymentInput({
    required this.creditCardId,
    required this.fromAccountId,
    required this.amount,
    required this.description,
    required this.paymentDate,
  });

  final String creditCardId;
  final String fromAccountId;
  final double amount;
  final String description;
  final DateTime paymentDate;
}
