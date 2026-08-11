import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';

DashboardSummary createDashboardSummary() {
  return const DashboardSummary(
    totalAccountBalances: 100000,
    totalCreditCardDebt: 5000,
    totalAssets: 100000,
    netWorth: 95000,
    monthlyIncome: 25000,
    monthlyExpense: 15000,
    monthlyCashFlow: 10000,
    transactionCount: 12,
  );
}
