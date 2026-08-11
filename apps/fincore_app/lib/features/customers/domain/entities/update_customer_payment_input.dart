final class UpdateCustomerPaymentInput {
  const UpdateCustomerPaymentInput({
    required this.transactionId,
    required this.accountId,
    required this.creditCardId,
    required this.amount,
    required this.description,
    required this.paymentDate,
  });

  final String transactionId;
  final String? accountId;
  final String? creditCardId;
  final double amount;
  final String description;
  final DateTime paymentDate;
}
