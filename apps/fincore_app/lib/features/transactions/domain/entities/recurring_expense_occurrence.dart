abstract final class RecurringExpenseOccurrence {
  static String transactionId({
    required String planId,
    required DateTime dueDate,
  }) {
    final date =
        '${dueDate.year.toString().padLeft(4, '0')}'
        '${dueDate.month.toString().padLeft(2, '0')}'
        '${dueDate.day.toString().padLeft(2, '0')}';
    return 'recurring-expense-occurrence-$planId-$date';
  }
}
