final class DashboardSummary {
  const DashboardSummary({
    required this.totalAccountBalances,
    required this.totalCreditCardDebt,
    required this.totalAssets,
    required this.netWorth,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlyCashFlow,
    required this.transactionCount,
  });

  final double totalAccountBalances;
  final double totalCreditCardDebt;
  final double totalAssets;
  final double netWorth;
  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlyCashFlow;
  final int transactionCount;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DashboardSummary &&
            totalAccountBalances == other.totalAccountBalances &&
            totalCreditCardDebt == other.totalCreditCardDebt &&
            totalAssets == other.totalAssets &&
            netWorth == other.netWorth &&
            monthlyIncome == other.monthlyIncome &&
            monthlyExpense == other.monthlyExpense &&
            monthlyCashFlow == other.monthlyCashFlow &&
            transactionCount == other.transactionCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      totalAccountBalances,
      totalCreditCardDebt,
      totalAssets,
      netWorth,
      monthlyIncome,
      monthlyExpense,
      monthlyCashFlow,
      transactionCount,
    );
  }
}
