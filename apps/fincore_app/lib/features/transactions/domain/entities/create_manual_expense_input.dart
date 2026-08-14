final class CreateManualExpenseInput {
  const CreateManualExpenseInput({
    required this.accountId,
    required this.creditCardId,
    this.customerId,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.transactionDate,
    this.installmentAmounts = const [],
  });

  final String? accountId;
  final String? creditCardId;
  final String? customerId;
  final double amount;
  final String description;
  final String? categoryId;
  final DateTime transactionDate;
  final List<double> installmentAmounts;
}
