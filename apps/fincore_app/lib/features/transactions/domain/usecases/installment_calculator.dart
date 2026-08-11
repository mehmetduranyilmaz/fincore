abstract final class InstallmentCalculator {
  static const int minimumCount = 2;
  static const int maximumCount = 36;

  static List<double> splitEvenly(double totalAmount, int count) {
    _validateTotal(totalAmount);
    _validateCount(count);

    final totalCents = toCents(totalAmount);
    if (totalCents < count) {
      throw ArgumentError.value(totalAmount, 'totalAmount');
    }
    final baseCents = totalCents ~/ count;
    final remainder = totalCents - (baseCents * count);
    return List.unmodifiable([
      for (var index = 0; index < count; index++)
        fromCents(baseCents + (index == count - 1 ? remainder : 0)),
    ]);
  }

  static void validateCustomAmounts(
    double totalAmount,
    List<double> installmentAmounts,
  ) {
    _validateTotal(totalAmount);
    _validateCount(installmentAmounts.length);
    if (installmentAmounts.any(
      (amount) => !amount.isFinite || toCents(amount) <= 0,
    )) {
      throw ArgumentError.value(installmentAmounts, 'installmentAmounts');
    }
    final sum = installmentAmounts.fold<int>(
      0,
      (total, amount) => total + toCents(amount),
    );
    if (sum != toCents(totalAmount)) {
      throw ArgumentError.value(installmentAmounts, 'installmentAmounts');
    }
  }

  static DateTime installmentDate(DateTime purchaseDate, int zeroBasedIndex) {
    if (zeroBasedIndex < 0) {
      throw ArgumentError.value(zeroBasedIndex, 'zeroBasedIndex');
    }
    final targetMonthStart = DateTime(
      purchaseDate.year,
      purchaseDate.month + zeroBasedIndex,
    );
    final lastDay = DateTime(
      targetMonthStart.year,
      targetMonthStart.month + 1,
      0,
    ).day;
    return DateTime(
      targetMonthStart.year,
      targetMonthStart.month,
      purchaseDate.day.clamp(1, lastDay).toInt(),
    );
  }

  static int toCents(double amount) => (amount * 100).round();

  static double fromCents(int cents) => cents / 100;

  static void _validateTotal(double totalAmount) {
    if (!totalAmount.isFinite || toCents(totalAmount) <= 0) {
      throw ArgumentError.value(totalAmount, 'totalAmount');
    }
  }

  static void _validateCount(int count) {
    if (count < minimumCount || count > maximumCount) {
      throw ArgumentError.value(count, 'count');
    }
  }
}
