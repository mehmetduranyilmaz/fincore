abstract final class CreditCardValidator {
  static const Set<String> supportedCurrencyCodes = {'TRY', 'USD', 'EUR'};

  static String validateRequiredText(
    String value, {
    required String argumentName,
    required int maxLength,
  }) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > maxLength) {
      throw ArgumentError.value(value, argumentName);
    }
    return normalized;
  }

  static String validateLastFourDigits(String value) {
    final normalized = value.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(normalized)) {
      throw ArgumentError.value(value, 'lastFourDigits');
    }
    return normalized;
  }

  static void validateCreditLimit(double value) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(value, 'creditLimit');
    }
  }

  static void validateDay(int value, String argumentName) {
    if (value < 1 || value > 31) {
      throw ArgumentError.value(value, argumentName);
    }
  }

  static String validateCurrencyCode(String value) {
    final normalized = value.trim().toUpperCase();
    if (!supportedCurrencyCodes.contains(normalized)) {
      throw ArgumentError.value(value, 'currencyCode');
    }
    return normalized;
  }
}
