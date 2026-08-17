final class CreateRecurringExpensePlanInput {
  const CreateRecurringExpensePlanInput({
    required this.accountId,
    required this.creditCardId,
    required this.customerId,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.firstDueDate,
    required this.occurrenceCount,
  });

  final String? accountId;
  final String? creditCardId;
  final String? customerId;
  final double amount;
  final String description;
  final String? categoryId;
  final DateTime firstDueDate;
  final int occurrenceCount;
}
