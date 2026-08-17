import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_payment_calendar.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/recurring_expense_plan_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';

typedef CreditCardPaymentCalendarClock = DateTime Function();

final class GetCreditCardPaymentCalendarUseCase {
  GetCreditCardPaymentCalendarUseCase(
    this._creditCardRepository,
    this._transactionRepository, {
    this._recurringExpensePlanRepository,
    CreditCardPaymentCalendarClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final CreditCardRepository _creditCardRepository;
  final TransactionRepository _transactionRepository;
  final RecurringExpensePlanRepository? _recurringExpensePlanRepository;
  final CreditCardPaymentCalendarClock _clock;

  Future<CreditCardPaymentCalendar> execute() async {
    final creditCards = await _creditCardRepository.getCreditCards();
    final currencyByCardId = {
      for (final card in creditCards) card.id: card.currencyCode,
    };
    final now = _clock();
    final firstVisibleMonth = DateTime(now.year, now.month);
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(transactionTypes: const {TransactionType.expense}),
    );
    final monthBuckets = <(int, int), _MonthBucket>{};

    for (final transaction in transactions) {
      final creditCardId = transaction.creditCardId;
      final currencyCode = currencyByCardId[creditCardId];
      if (creditCardId == null ||
          currencyCode == null ||
          transaction.isDeleted ||
          transaction.transactionType != TransactionType.expense ||
          transaction.transactionDate.isBefore(firstVisibleMonth)) {
        continue;
      }

      final key = (
        transaction.transactionDate.year,
        transaction.transactionDate.month,
      );
      final bucket = monthBuckets.putIfAbsent(key, _MonthBucket.new);
      bucket.transactionCount++;
      bucket.centsByCurrency.update(
        currencyCode,
        (value) =>
            value + InstallmentCalculator.toCents(transaction.amount.abs()),
        ifAbsent: () => InstallmentCalculator.toCents(transaction.amount.abs()),
      );
    }

    final recurringPlans =
        await _recurringExpensePlanRepository?.getPlans() ?? const [];
    for (final plan in recurringPlans) {
      for (final dueDate in plan.dueDates) {
        if (dueDate.isBefore(firstVisibleMonth)) continue;
        final key = (dueDate.year, dueDate.month);
        final bucket = monthBuckets.putIfAbsent(key, _MonthBucket.new);
        bucket.transactionCount++;
        bucket.plannedExpenseCount++;
        bucket.centsByCurrency.update(
          plan.currencyCode,
          (value) => value + InstallmentCalculator.toCents(plan.amount.abs()),
          ifAbsent: () => InstallmentCalculator.toCents(plan.amount.abs()),
        );
      }
    }

    final sortedKeys = monthBuckets.keys.toList()
      ..sort((left, right) {
        final yearComparison = left.$1.compareTo(right.$1);
        return yearComparison != 0
            ? yearComparison
            : left.$2.compareTo(right.$2);
      });
    final monthsByYear = <int, List<CreditCardPaymentMonth>>{};
    final yearCents = <int, Map<String, int>>{};

    for (final key in sortedKeys) {
      final bucket = monthBuckets[key]!;
      final totals = _toAmounts(bucket.centsByCurrency);
      monthsByYear
          .putIfAbsent(key.$1, () => [])
          .add(
            CreditCardPaymentMonth(
              year: key.$1,
              month: key.$2,
              totalsByCurrency: totals,
              transactionCount: bucket.transactionCount,
              plannedExpenseCount: bucket.plannedExpenseCount,
            ),
          );
      final totalsForYear = yearCents.putIfAbsent(key.$1, () => {});
      for (final entry in bucket.centsByCurrency.entries) {
        totalsForYear.update(
          entry.key,
          (value) => value + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }

    return CreditCardPaymentCalendar([
      for (final entry in monthsByYear.entries)
        CreditCardPaymentYear(
          year: entry.key,
          months: entry.value,
          totalsByCurrency: _toAmounts(yearCents[entry.key]!),
        ),
    ]);
  }

  static Map<String, double> _toAmounts(Map<String, int> cents) {
    final currencies = cents.keys.toList()..sort();
    return {
      for (final currency in currencies)
        currency: InstallmentCalculator.fromCents(cents[currency]!),
    };
  }
}

final class _MonthBucket {
  final Map<String, int> centsByCurrency = {};
  int transactionCount = 0;
  int plannedExpenseCount = 0;
}
