final class CreateReceiptExpenseInput {
  const CreateReceiptExpenseInput({
    required this.accountId,
    required this.creditCardId,
    required this.totalAmount,
    required this.installmentAmounts,
    required this.description,
    required this.categoryId,
    required this.transactionDate,
  });

  final String? accountId;
  final String? creditCardId;
  final double totalAmount;
  final List<double> installmentAmounts;
  final String description;
  final String? categoryId;
  final DateTime transactionDate;
}
