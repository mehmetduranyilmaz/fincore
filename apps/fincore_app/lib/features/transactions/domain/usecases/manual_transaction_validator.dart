abstract final class ManualTransactionValidator {
  static void validateAmount(double amount) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(amount, 'amount');
    }
  }

  static void validateDescription(String description) {
    if (description.trim().isEmpty) {
      throw ArgumentError.value(description, 'description');
    }
  }

  static void validateRequiredId(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name);
    }
  }

  static void validateDate(DateTime date, DateTime now) {
    if (date.isAfter(now)) {
      throw ArgumentError.value(date, 'transactionDate');
    }
  }
}
