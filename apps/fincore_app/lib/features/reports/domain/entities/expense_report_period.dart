enum ExpenseReportPeriodType { monthly, yearly }

final class ExpenseReportPeriod {
  factory ExpenseReportPeriod.month(DateTime date) {
    final start = DateTime(date.year, date.month);
    return ExpenseReportPeriod._(
      type: ExpenseReportPeriodType.monthly,
      anchor: start,
      startDate: start,
      endDate: DateTime(date.year, date.month + 1, 0),
    );
  }

  factory ExpenseReportPeriod.year(DateTime date) {
    final start = DateTime(date.year);
    return ExpenseReportPeriod._(
      type: ExpenseReportPeriodType.yearly,
      anchor: start,
      startDate: start,
      endDate: DateTime(date.year, 12, 31),
    );
  }

  const ExpenseReportPeriod._({
    required this.type,
    required this.anchor,
    required this.startDate,
    required this.endDate,
  });

  final ExpenseReportPeriodType type;
  final DateTime anchor;
  final DateTime startDate;
  final DateTime endDate;

  ExpenseReportPeriod previous() {
    return switch (type) {
      ExpenseReportPeriodType.monthly => ExpenseReportPeriod.month(
        DateTime(anchor.year, anchor.month - 1),
      ),
      ExpenseReportPeriodType.yearly => ExpenseReportPeriod.year(
        DateTime(anchor.year - 1),
      ),
    };
  }

  ExpenseReportPeriod next() {
    return switch (type) {
      ExpenseReportPeriodType.monthly => ExpenseReportPeriod.month(
        DateTime(anchor.year, anchor.month + 1),
      ),
      ExpenseReportPeriodType.yearly => ExpenseReportPeriod.year(
        DateTime(anchor.year + 1),
      ),
    };
  }

  ExpenseReportPeriod changeType(ExpenseReportPeriodType value) {
    return switch (value) {
      ExpenseReportPeriodType.monthly => ExpenseReportPeriod.month(anchor),
      ExpenseReportPeriodType.yearly => ExpenseReportPeriod.year(anchor),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExpenseReportPeriod &&
            type == other.type &&
            anchor == other.anchor;
  }

  @override
  int get hashCode => Object.hash(type, anchor);
}
