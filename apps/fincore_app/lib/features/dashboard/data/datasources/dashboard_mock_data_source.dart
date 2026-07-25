import 'package:fincore_app/features/dashboard/domain/entities/category_spending.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/dashboard/domain/entities/recent_transaction.dart';
import 'package:fincore_app/features/dashboard/domain/entities/upcoming_payment.dart';

abstract interface class DashboardDataSource {
  Future<DashboardSummary> getSummary();
}

final class DashboardMockDataSource implements DashboardDataSource {
  const DashboardMockDataSource();

  @override
  Future<DashboardSummary> getSummary() async {
    return DashboardSummary(
      totalBalance: 125750.40,
      monthlyExpense: 18420.75,
      creditCardDebt: 7250,
      upcomingPayments: [
        UpcomingPayment(
          id: 'payment-1',
          title: 'Office Rent',
          amount: 12500,
          dueDate: DateTime(2026, 8, 1),
        ),
        UpcomingPayment(
          id: 'payment-2',
          title: 'Credit Card',
          amount: 7250,
          dueDate: DateTime(2026, 8, 5),
        ),
        UpcomingPayment(
          id: 'payment-3',
          title: 'Internet',
          amount: 890,
          dueDate: DateTime(2026, 8, 10),
        ),
      ],
      recentTransactions: [
        RecentTransaction(
          id: 'transaction-1',
          description: 'Client Payment',
          amount: 32000,
          occurredAt: DateTime(2026, 7, 24),
          type: TransactionType.income,
        ),
        RecentTransaction(
          id: 'transaction-2',
          description: 'Office Supplies',
          amount: 2450.50,
          occurredAt: DateTime(2026, 7, 23),
          type: TransactionType.expense,
        ),
        RecentTransaction(
          id: 'transaction-3',
          description: 'Software Subscription',
          amount: 1250,
          occurredAt: DateTime(2026, 7, 22),
          type: TransactionType.expense,
        ),
      ],
      categorySpendings: const [
        CategorySpending(
          category: 'Operations',
          amount: 8200,
          percentage: 0.45,
        ),
        CategorySpending(category: 'Software', amount: 5100, percentage: 0.28),
        CategorySpending(category: 'Travel', amount: 3120.75, percentage: 0.17),
        CategorySpending(category: 'Other', amount: 2000, percentage: 0.10),
      ],
    );
  }
}
