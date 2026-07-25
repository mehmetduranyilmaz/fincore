import 'package:fincore_app/features/dashboard/domain/entities/category_spending.dart';
import 'package:fincore_app/features/dashboard/domain/entities/recent_transaction.dart';
import 'package:fincore_app/features/dashboard/domain/entities/upcoming_payment.dart';

final class DashboardSummary {
  DashboardSummary({
    required this.totalBalance,
    required this.monthlyExpense,
    required this.creditCardDebt,
    required List<UpcomingPayment> upcomingPayments,
    required List<RecentTransaction> recentTransactions,
    required List<CategorySpending> categorySpendings,
  }) : upcomingPayments = List.unmodifiable(upcomingPayments),
       recentTransactions = List.unmodifiable(recentTransactions),
       categorySpendings = List.unmodifiable(categorySpendings);

  final double totalBalance;
  final double monthlyExpense;
  final double creditCardDebt;
  final List<UpcomingPayment> upcomingPayments;
  final List<RecentTransaction> recentTransactions;
  final List<CategorySpending> categorySpendings;
}
