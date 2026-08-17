final class RecurringExpensePlan {
  RecurringExpensePlan({
    required this.id,
    required this.accountId,
    required this.creditCardId,
    required this.customerId,
    required this.amount,
    required this.description,
    required this.categoryId,
    required this.currencyCode,
    required DateTime firstDueDate,
    required this.occurrenceCount,
  }) : firstDueDate = DateTime(
         firstDueDate.year,
         firstDueDate.month,
         firstDueDate.day,
       ) {
    final sourceCount = [accountId, creditCardId, customerId].nonNulls.length;
    if (id.trim().isEmpty ||
        sourceCount != 1 ||
        !amount.isFinite ||
        amount <= 0 ||
        description.trim().isEmpty ||
        currencyCode.trim().isEmpty ||
        occurrenceCount < minimumOccurrenceCount ||
        occurrenceCount > maximumOccurrenceCount) {
      throw ArgumentError('Invalid recurring expense plan.');
    }
  }

  static const int minimumOccurrenceCount = 2;
  static const int maximumOccurrenceCount = 60;

  final String id;
  final String? accountId;
  final String? creditCardId;
  final String? customerId;
  final double amount;
  final String description;
  final String? categoryId;
  final String currencyCode;
  final DateTime firstDueDate;
  final int occurrenceCount;

  Iterable<DateTime> get dueDates sync* {
    for (var index = 0; index < occurrenceCount; index++) {
      final targetMonth = DateTime(
        firstDueDate.year,
        firstDueDate.month + index,
      );
      final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
      yield DateTime(
        targetMonth.year,
        targetMonth.month,
        firstDueDate.day.clamp(1, lastDay),
      );
    }
  }
}
