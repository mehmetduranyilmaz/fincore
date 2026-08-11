final class CreateManualIncomeInput {
  const CreateManualIncomeInput({
    required this.accountId,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.transactionDate,
  });

  final String accountId;
  final double amount;
  final String description;
  final String? categoryId;
  final DateTime transactionDate;
}
