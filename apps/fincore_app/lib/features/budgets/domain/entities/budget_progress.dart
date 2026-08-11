final class BudgetProgress {
  const BudgetProgress._({
    required this.budgetAmount,
    required this.spentAmount,
    required this.remainingAmount,
    required this.progress,
  });

  factory BudgetProgress.calculate({
    required double budgetAmount,
    required double spentAmount,
  }) {
    return BudgetProgress._(
      budgetAmount: budgetAmount,
      spentAmount: spentAmount,
      remainingAmount: budgetAmount - spentAmount,
      progress: budgetAmount == 0 ? 0 : spentAmount / budgetAmount,
    );
  }

  final double budgetAmount;
  final double spentAmount;
  final double remainingAmount;
  final double progress;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BudgetProgress &&
            budgetAmount == other.budgetAmount &&
            spentAmount == other.spentAmount &&
            remainingAmount == other.remainingAmount &&
            progress == other.progress;
  }

  @override
  int get hashCode {
    return Object.hash(budgetAmount, spentAmount, remainingAmount, progress);
  }
}
