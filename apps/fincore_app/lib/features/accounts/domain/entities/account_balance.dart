final class AccountBalance {
  const AccountBalance({
    required this.currentBalance,
    required this.totalIncome,
    required this.totalExpense,
  });

  final double currentBalance;
  final double totalIncome;
  final double totalExpense;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AccountBalance &&
            currentBalance == other.currentBalance &&
            totalIncome == other.totalIncome &&
            totalExpense == other.totalExpense;
  }

  @override
  int get hashCode {
    return Object.hash(currentBalance, totalIncome, totalExpense);
  }
}
