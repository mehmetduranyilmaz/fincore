final class CashFlowEntry {
  const CashFlowEntry({
    required this.transactionId,
    required this.description,
    required this.accountName,
    required this.currencyCode,
    required this.amount,
    required this.isInflow,
  });

  final String transactionId;
  final String description;
  final String accountName;
  final String currencyCode;
  final double amount;
  final bool isInflow;
}

final class CashFlowAccountBalance {
  const CashFlowAccountBalance({
    required this.accountName,
    required this.currencyCode,
    required this.balance,
    required this.isCash,
  });

  final String accountName;
  final String currencyCode;
  final double balance;
  final bool isCash;
}

final class CashFlowReport {
  CashFlowReport({
    required List<CashFlowEntry> inflows,
    required List<CashFlowEntry> outflows,
    required List<CashFlowAccountBalance> accountBalances,
  }) : inflows = List.unmodifiable(inflows),
       outflows = List.unmodifiable(outflows),
       accountBalances = List.unmodifiable(accountBalances);

  final List<CashFlowEntry> inflows;
  final List<CashFlowEntry> outflows;
  final List<CashFlowAccountBalance> accountBalances;

  Map<String, double> get totalInflows => _sumEntries(inflows);
  Map<String, double> get totalOutflows => _sumEntries(outflows);
  Map<String, double> get netByCurrency => {
    for (final currency in {...totalInflows.keys, ...totalOutflows.keys})
      currency: (totalInflows[currency] ?? 0) - (totalOutflows[currency] ?? 0),
  };
  Map<String, double> get liquidBalances => _sumBalances(accountBalances);
  Map<String, double> get cashBalances =>
      _sumBalances(accountBalances.where((item) => item.isCash));
  Map<String, double> get bankBalances =>
      _sumBalances(accountBalances.where((item) => !item.isCash));

  static Map<String, double> _sumEntries(Iterable<CashFlowEntry> entries) {
    final result = <String, double>{};
    for (final entry in entries) {
      result.update(
        entry.currencyCode,
        (value) => value + entry.amount,
        ifAbsent: () => entry.amount,
      );
    }
    return result;
  }

  static Map<String, double> _sumBalances(
    Iterable<CashFlowAccountBalance> balances,
  ) {
    final result = <String, double>{};
    for (final item in balances) {
      result.update(
        item.currencyCode,
        (value) => value + item.balance,
        ifAbsent: () => item.balance,
      );
    }
    return result;
  }
}
