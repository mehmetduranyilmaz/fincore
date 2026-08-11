import 'package:fincore_app/features/reports/domain/entities/expense_report_period.dart';

final class ExpenseCategoryReport {
  ExpenseCategoryReport({
    required this.period,
    required List<CurrencyExpenseReport> currencies,
  }) : currencies = List.unmodifiable(currencies);

  final ExpenseReportPeriod period;
  final List<CurrencyExpenseReport> currencies;

  bool get isEmpty => currencies.every((item) => item.transactionCount == 0);
}

final class CurrencyExpenseReport {
  CurrencyExpenseReport({
    required this.currencyCode,
    required this.totalAmount,
    required this.transactionCount,
    required List<CategoryExpenseBreakdown> categories,
  }) : categories = List.unmodifiable(categories);

  final String currencyCode;
  final double totalAmount;
  final int transactionCount;
  final List<CategoryExpenseBreakdown> categories;

  double get averageTransactionAmount {
    return transactionCount == 0 ? 0 : totalAmount / transactionCount;
  }
}

final class CategoryExpenseBreakdown {
  CategoryExpenseBreakdown({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    required List<ExpenseReportTransaction> transactions,
  }) : transactions = List.unmodifiable(transactions);

  final String? categoryId;
  final String name;
  final String icon;
  final int color;
  final double amount;
  final double percentage;
  final int transactionCount;
  final List<ExpenseReportTransaction> transactions;
}

final class ExpenseReportTransaction {
  const ExpenseReportTransaction({
    required this.id,
    required this.description,
    required this.date,
    required this.amount,
  });

  final String id;
  final String description;
  final DateTime date;
  final double amount;
}
