enum CreditCardPaymentDetailKind { creditCard, customer, account }

final class CreditCardPaymentDetail {
  CreditCardPaymentDetail({
    required this.sourceId,
    required this.kind,
    required this.label,
    required Map<String, double> totalsByCurrency,
    Map<String, double> paidByCurrency = const {},
    required this.transactionCount,
    this.plannedExpenseCount = 0,
  }) : totalsByCurrency = Map.unmodifiable(totalsByCurrency),
       paidByCurrency = Map.unmodifiable(paidByCurrency) {
    if (sourceId.trim().isEmpty ||
        label.trim().isEmpty ||
        transactionCount < 1 ||
        plannedExpenseCount < 0 ||
        plannedExpenseCount > transactionCount ||
        totalsByCurrency.isEmpty) {
      throw ArgumentError('Invalid credit card payment detail.');
    }
  }

  final String sourceId;
  final CreditCardPaymentDetailKind kind;
  final String label;
  final Map<String, double> totalsByCurrency;
  final Map<String, double> paidByCurrency;
  final int transactionCount;
  final int plannedExpenseCount;

  int get confirmedTransactionCount => transactionCount - plannedExpenseCount;

  bool get isPaid => totalsByCurrency.entries.every(
    (entry) => (paidByCurrency[entry.key] ?? 0) >= entry.value,
  );
}

final class CreditCardPaymentMonth {
  CreditCardPaymentMonth({
    required this.year,
    required this.month,
    required Map<String, double> totalsByCurrency,
    Map<String, double> paidByCurrency = const {},
    required this.transactionCount,
    this.plannedExpenseCount = 0,
    List<CreditCardPaymentDetail> details = const [],
  }) : totalsByCurrency = Map.unmodifiable(totalsByCurrency),
       paidByCurrency = Map.unmodifiable(paidByCurrency),
       details = List.unmodifiable(details) {
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
  final Map<String, double> paidByCurrency;
  final int transactionCount;
  final int plannedExpenseCount;
  final List<CreditCardPaymentDetail> details;

  int get confirmedTransactionCount => transactionCount - plannedExpenseCount;

  Map<String, double> get remainingByCurrency => {
    for (final entry in totalsByCurrency.entries)
      entry.key: (entry.value - (paidByCurrency[entry.key] ?? 0)).clamp(
        0,
        double.infinity,
      ),
  };

  double get completionRatio {
    final total = totalsByCurrency.values.fold(
      0.0,
      (sum, value) => sum + value,
    );
    if (total <= 0) return 0;
    final paid = totalsByCurrency.entries.fold(
      0.0,
      (sum, entry) =>
          sum + (paidByCurrency[entry.key] ?? 0).clamp(0, entry.value),
    );
    return (paid / total).clamp(0, 1);
  }

  bool get isPaid => completionRatio >= 1;

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
