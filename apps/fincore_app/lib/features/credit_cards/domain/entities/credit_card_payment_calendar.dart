final class CreditCardPaymentMonth {
  CreditCardPaymentMonth({
    required this.year,
    required this.month,
    required Map<String, double> totalsByCurrency,
    required this.transactionCount,
    this.plannedExpenseCount = 0,
  }) : totalsByCurrency = Map.unmodifiable(totalsByCurrency) {
    if (year < 1 ||
        month < 1 ||
        month > 12 ||
        transactionCount < 1 ||
        plannedExpenseCount < 0 ||
        plannedExpenseCount > transactionCount) {
      throw ArgumentError('Invalid credit card payment month.');
    }
  }

  final int year;
  final int month;
  final Map<String, double> totalsByCurrency;
  final int transactionCount;
  final int plannedExpenseCount;

  int get confirmedTransactionCount => transactionCount - plannedExpenseCount;

  String get periodLabel => '$year-${month.toString().padLeft(2, '0')}';
}

final class CreditCardPaymentYear {
  CreditCardPaymentYear({
    required this.year,
    required List<CreditCardPaymentMonth> months,
    required Map<String, double> totalsByCurrency,
  }) : months = List.unmodifiable(months),
       totalsByCurrency = Map.unmodifiable(totalsByCurrency) {
    if (year < 1 ||
        months.isEmpty ||
        months.any((month) => month.year != year)) {
      throw ArgumentError('Invalid credit card payment year.');
    }
  }

  final int year;
  final List<CreditCardPaymentMonth> months;
  final Map<String, double> totalsByCurrency;
}

final class CreditCardPaymentCalendar {
  CreditCardPaymentCalendar(List<CreditCardPaymentYear> years)
    : years = List.unmodifiable(years);

  final List<CreditCardPaymentYear> years;

  bool get isEmpty => years.isEmpty;
}
