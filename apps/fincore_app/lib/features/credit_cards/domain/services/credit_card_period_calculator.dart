import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';

abstract final class CreditCardPeriodCalculator {
  /// Spending month a statement closes: the month whose expected cut date
  /// (the card's statement day) is nearest to the actual statement date. A
  /// statement cut on 1 October for a card closing on the 31st therefore
  /// belongs to September, not October.
  static DateTime statementPeriod({
    required DateTime statementDate,
    required int statementDay,
  }) {
    final day = _dateOnly(statementDate);
    DateTime? best;
    var bestDistance = 0;
    for (final offset in const [-1, 0, 1]) {
      final cut = _dateWithClampedDay(
        year: day.year,
        month: day.month + offset,
        day: statementDay,
      );
      final distance = cut.difference(day).inDays.abs();
      if (best == null || distance < bestDistance) {
        best = cut;
        bestDistance = distance;
      }
    }
    return DateTime(best!.year, best.month);
  }

  static DateTime transactionPeriod({
    required String transactionId,
    required DateTime transactionDate,
    required int statementDay,
    List<CreditCardStatement> statements = const [],
  }) {
    for (final statement in statements) {
      if (statement.lines.any((line) => line.transactionId == transactionId)) {
        return statementPeriod(
          statementDate: statement.statementDate,
          statementDay: statementDay,
        );
      }
    }

    final transactionDay = _dateOnly(transactionDate);
    final cutoff = _dateWithClampedDay(
      year: transactionDay.year,
      month: transactionDay.month,
      day: statementDay,
    );
    final byCutoff = transactionDay.isAfter(cutoff)
        ? DateTime(transactionDay.year, transactionDay.month + 1)
        : DateTime(transactionDay.year, transactionDay.month);

    // A charge after a statement was cut cannot belong to that statement's
    // period or an earlier one.
    final completedStatement = statements
        .where(
          (statement) =>
              !_dateOnly(statement.statementDate).isAfter(transactionDay),
        )
        .fold<CreditCardStatement?>(null, (latest, statement) {
          if (latest == null ||
              statement.statementDate.isAfter(latest.statementDate)) {
            return statement;
          }
          return latest;
        });
    if (completedStatement == null) return byCutoff;
    final closedPeriod = statementPeriod(
      statementDate: completedStatement.statementDate,
      statementDay: statementDay,
    );
    final firstOpenPeriod = DateTime(closedPeriod.year, closedPeriod.month + 1);
    return byCutoff.isBefore(firstOpenPeriod) ? firstOpenPeriod : byCutoff;
  }

  static DateTime upcomingStatementDate({
    required DateTime referenceDate,
    required int statementDay,
  }) {
    final today = _dateOnly(referenceDate);
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

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _dateWithClampedDay({
    required int year,
    required int month,
    required int day,
  }) {
    final monthStart = DateTime(year, month);
    final lastDay = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    return DateTime(monthStart.year, monthStart.month, day.clamp(1, lastDay));
  }
}
