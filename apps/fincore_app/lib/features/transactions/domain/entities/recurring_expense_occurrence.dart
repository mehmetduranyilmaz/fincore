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

  static bool belongsToPlan(String transactionId, String planId) {
    const prefix = 'recurring-expense-occurrence-';
    final planPrefix = '$prefix$planId-';
    return transactionId.startsWith(planPrefix) &&
        RegExp(r'^\d{8}$').hasMatch(transactionId.substring(planPrefix.length));
  }

  /// Due date encoded in an occurrence transaction id, or null for any other
  /// transaction.
  static DateTime? dueDateOf(String transactionId) {
    if (!transactionId.startsWith('recurring-expense-occurrence-')) return null;
    final match = RegExp(r'-(\d{4})(\d{2})(\d{2})$').firstMatch(transactionId);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }
}
