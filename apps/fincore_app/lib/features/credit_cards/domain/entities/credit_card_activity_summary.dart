final class CreditCardActivitySummary {
  const CreditCardActivitySummary({
    required this.statementAmount,
    required this.currentPeriodAmount,
    required this.futureInstallmentAmount,
  });

  final double statementAmount;
  final double currentPeriodAmount;
  final double futureInstallmentAmount;
}
