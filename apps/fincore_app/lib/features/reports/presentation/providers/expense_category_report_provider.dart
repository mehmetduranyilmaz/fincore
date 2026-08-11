import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/reports/domain/entities/expense_category_report.dart';
import 'package:fincore_app/features/reports/presentation/controllers/expense_report_period_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final expenseCategoryReportProvider =
    FutureProvider.autoDispose<ExpenseCategoryReport>((ref) {
      final period = ref.watch(expenseReportPeriodControllerProvider);
      return ref.watch(calculateExpenseCategoryReportProvider).execute(period);
    });
