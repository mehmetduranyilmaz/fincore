final class UpdateTransactionInput {
  const UpdateTransactionInput({
    required this.transactionId,
    required this.accountId,
    required this.creditCardId,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.transactionDate,
  });

  final String transactionId;
  final String? accountId;
  final String? creditCardId;
  final double amount;
  final String description;
  final String? categoryId;
  final DateTime transactionDate;
}
