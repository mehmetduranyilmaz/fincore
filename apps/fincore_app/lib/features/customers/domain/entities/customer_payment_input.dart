enum CustomerPaymentDirection { collect, pay }

final class CustomerPaymentInput {
  const CustomerPaymentInput({
    required this.customerId,
    required this.direction,
    required this.accountId,
    required this.creditCardId,
    required this.amount,
    required this.description,
    required this.paymentDate,
  });

  final String customerId;
  final CustomerPaymentDirection direction;
  final String? accountId;
  final String? creditCardId;
  final double amount;
  final String description;
  final DateTime paymentDate;
}
