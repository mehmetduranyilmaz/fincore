abstract final class CreditCardPeriodCalculator {
  static DateTime upcomingStatementDate({
    required DateTime referenceDate,
    required int statementDay,
  }) {
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final thisMonth = _dateWithClampedDay(
      year: today.year,
      month: today.month,
      day: statementDay,
    );
    if (!thisMonth.isBefore(today)) return thisMonth;
    return _dateWithClampedDay(
      year: today.year,
      month: today.month + 1,
      day: statementDay,
    );
  }

  static DateTime _dateWithClampedDay({
    required int year,
    required int month,
    required int day,
  }) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay));
  }
}
