import 'package:fincore_app/features/reports/domain/entities/expense_report_period.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final expenseReportPeriodControllerProvider =
    NotifierProvider<ExpenseReportPeriodController, ExpenseReportPeriod>(
      ExpenseReportPeriodController.new,
    );

final class ExpenseReportPeriodController
    extends Notifier<ExpenseReportPeriod> {
  @override
  ExpenseReportPeriod build() => ExpenseReportPeriod.month(DateTime.now());

  void previous() => state = state.previous();

  void next() => state = state.next();

  void changeType(ExpenseReportPeriodType type) {
    state = state.changeType(type);
  }

  void current() {
    state = switch (state.type) {
      ExpenseReportPeriodType.monthly => ExpenseReportPeriod.month(
        DateTime.now(),
      ),
      ExpenseReportPeriodType.yearly => ExpenseReportPeriod.year(
        DateTime.now(),
      ),
    };
  }
}
