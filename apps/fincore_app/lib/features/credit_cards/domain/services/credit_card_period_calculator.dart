import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';

abstract final class CreditCardPeriodCalculator {
  static DateTime transactionPeriod({
    required String transactionId,
    required DateTime transactionDate,
    required int statementDay,
    List<CreditCardStatement> statements = const [],
  }) {
    for (final statement in statements) {
      if (statement.lines.any((line) => line.transactionId == transactionId)) {
        return DateTime(
          statement.statementDate.year,
          statement.statementDate.month,
        );
      }
    }

    final transactionDay = DateTime(
      transactionDate.year,
      transactionDate.month,
      transactionDate.day,
    );
    final completedStatement = statements
        .where((statement) {
          final date = DateTime(
            statement.statementDate.year,
            statement.statementDate.month,
            statement.statementDate.day,
          );
          return !date.isAfter(transactionDay);
        })
        .fold<CreditCardStatement?>(null, (latest, statement) {
          if (latest == null ||
              statement.statementDate.isAfter(latest.statementDate)) {
            return statement;
          }
          return latest;
        });
    if (completedStatement != null &&
        completedStatement.statementDate.year == transactionDay.year &&
        completedStatement.statementDate.month == transactionDay.month) {
      return DateTime(transactionDay.year, transactionDay.month + 1);
    }

    final cutoff = _dateWithClampedDay(
      year: transactionDay.year,
      month: transactionDay.month,
      day: statementDay,
    );
    return transactionDay.isAfter(cutoff)
        ? DateTime(transactionDay.year, transactionDay.month + 1)
        : DateTime(transactionDay.year, transactionDay.month);
  }

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
