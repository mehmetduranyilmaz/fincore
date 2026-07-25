import 'package:fincore_app/features/dashboard/domain/entities/category_spending.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/dashboard/domain/entities/recent_transaction.dart';
import 'package:fincore_app/features/dashboard/domain/entities/upcoming_payment.dart';

DashboardSummary createDashboardSummary() {
  return DashboardSummary(
    totalBalance: 100000,
    monthlyExpense: 15000,
    creditCardDebt: 5000,
    upcomingPayments: [
      UpcomingPayment(
        id: 'payment-1',
        title: 'Test Payment',
        amount: 1000,
        dueDate: DateTime(2026, 8),
      ),
    ],
    recentTransactions: [
      RecentTransaction(
        id: 'transaction-1',
        description: 'Test Transaction',
        amount: 2500,
        occurredAt: DateTime(2026, 7, 25),
        type: TransactionType.income,
      ),
    ],
    categorySpendings: const [
      CategorySpending(
        category: 'Test Category',
        amount: 1500,
        percentage: 0.5,
      ),
    ],
  );
}
