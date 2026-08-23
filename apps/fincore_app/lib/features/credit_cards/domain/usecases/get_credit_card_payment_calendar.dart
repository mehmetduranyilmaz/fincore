import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_payment_calendar.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_occurrence.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/recurring_expense_plan_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';

typedef CreditCardPaymentCalendarClock = DateTime Function();

final class GetCreditCardPaymentCalendarUseCase {
  GetCreditCardPaymentCalendarUseCase(
    this._creditCardRepository,
    this._transactionRepository, {
    this._recurringExpensePlanRepository,
    this._accountRepository,
    this._customerRepository,
    CreditCardPaymentCalendarClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final CreditCardRepository _creditCardRepository;
  final TransactionRepository _transactionRepository;
  final RecurringExpensePlanRepository? _recurringExpensePlanRepository;
  final AccountRepository? _accountRepository;
  final CustomerRepository? _customerRepository;
  final CreditCardPaymentCalendarClock _clock;

  Future<CreditCardPaymentCalendar> execute() async {
    final creditCards = await _creditCardRepository.getCreditCards();
    final cardById = {for (final card in creditCards) card.id: card};
    final accounts = await _accountRepository?.getAccounts() ?? const [];
    final accountNames = {
      for (final account in accounts) account.id: account.name,
    };
    final customers = await _customerRepository?.getCustomers() ?? const [];
    final customerNames = {
      for (final customer in customers) customer.id: customer.name,
    };
    final now = _clock();
    final firstVisibleMonth = DateTime(now.year, now.month);
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(transactionTypes: const {TransactionType.expense}),
    );
    final existingTransactionIds = transactions.map((item) => item.id).toSet();
    final monthBuckets = <(int, int), _MonthBucket>{};

    for (final transaction in transactions) {
      final creditCardId = transaction.creditCardId;
      final card = cardById[creditCardId];
      if (creditCardId == null ||
          card == null ||
          transaction.isDeleted ||
          transaction.source == TransactionSource.recurringPlan ||
          transaction.transactionType != TransactionType.expense ||
          transaction.transactionDate.isBefore(firstVisibleMonth)) {
        continue;
      }

      final bucket = monthBuckets.putIfAbsent((
        transaction.transactionDate.year,
        transaction.transactionDate.month,
      ), _MonthBucket.new);
      bucket.add(
        currencyCode: card.currencyCode,
        amount: transaction.amount,
        detailKey: (CreditCardPaymentDetailKind.creditCard, card.id),
        detailLabel: _cardLabel(card),
        planned: false,
      );
    }

    final recurringPlans =
        await _recurringExpensePlanRepository?.getPlans() ?? const [];
    for (final plan in recurringPlans) {
      final detail = _planDetail(
        plan,
        cardById: cardById,
        accountNames: accountNames,
        customerNames: customerNames,
      );
      for (final dueDate in plan.dueDates) {
        if (dueDate.isBefore(firstVisibleMonth)) continue;
        final realized = existingTransactionIds.contains(
          RecurringExpenseOccurrence.transactionId(
            planId: plan.id,
            dueDate: dueDate,
          ),
        );
        final bucket = monthBuckets.putIfAbsent((
          dueDate.year,
          dueDate.month,
        ), _MonthBucket.new);
        bucket.add(
          currencyCode: plan.currencyCode,
          amount: plan.amount,
          detailKey: (detail.kind, detail.sourceId),
          detailLabel: detail.label,
          planned: !realized,
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
      final details =
          bucket.details.entries.map((entry) {
            final detail = entry.value;
            return CreditCardPaymentDetail(
              sourceId: entry.key.$2,
              kind: entry.key.$1,
              label: detail.label,
              totalsByCurrency: _toAmounts(detail.centsByCurrency),
              transactionCount: detail.transactionCount,
              plannedExpenseCount: detail.plannedExpenseCount,
            );
          }).toList()..sort((left, right) {
            final kindComparison = left.kind.index.compareTo(right.kind.index);
            return kindComparison != 0
                ? kindComparison
                : left.label.toLowerCase().compareTo(right.label.toLowerCase());
          });
      monthsByYear
          .putIfAbsent(key.$1, () => [])
          .add(
            CreditCardPaymentMonth(
              year: key.$1,
              month: key.$2,
              totalsByCurrency: _toAmounts(bucket.centsByCurrency),
              transactionCount: bucket.transactionCount,
              plannedExpenseCount: bucket.plannedExpenseCount,
              details: details,
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

  static _PlanDetail _planDetail(
    RecurringExpensePlan plan, {
    required Map<String, CreditCard> cardById,
    required Map<String, String> accountNames,
    required Map<String, String> customerNames,
  }) {
    if (plan.creditCardId case final cardId?) {
      final card = cardById[cardId];
      return _PlanDetail(
        kind: CreditCardPaymentDetailKind.creditCard,
        sourceId: cardId,
        label: card == null ? 'Kredi Kartı • $cardId' : _cardLabel(card),
      );
    }
    if (plan.customerId case final customerId?) {
      return _PlanDetail(
        kind: CreditCardPaymentDetailKind.customer,
        sourceId: customerId,
        label: 'Müşteri • ${customerNames[customerId] ?? customerId}',
      );
    }
    final accountId = plan.accountId!;
    return _PlanDetail(
      kind: CreditCardPaymentDetailKind.account,
      sourceId: accountId,
      label: 'Hesap • ${accountNames[accountId] ?? accountId}',
    );
  }

  static String _cardLabel(CreditCard card) =>
      'Kredi Kartı • ${card.bankName} ${card.cardName} • ****${card.lastFourDigits}';

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
  final Map<(CreditCardPaymentDetailKind, String), _DetailBucket> details = {};
  int transactionCount = 0;
  int plannedExpenseCount = 0;

  void add({
    required String currencyCode,
    required double amount,
    required (CreditCardPaymentDetailKind, String) detailKey,
    required String detailLabel,
    required bool planned,
  }) {
    final cents = InstallmentCalculator.toCents(amount.abs());
    transactionCount++;
    if (planned) plannedExpenseCount++;
    centsByCurrency.update(
      currencyCode,
      (value) => value + cents,
      ifAbsent: () => cents,
    );
    details
        .putIfAbsent(detailKey, () => _DetailBucket(detailLabel))
        .add(currencyCode: currencyCode, cents: cents, planned: planned);
  }
}

final class _DetailBucket {
  _DetailBucket(this.label);

  final String label;
  final Map<String, int> centsByCurrency = {};
  int transactionCount = 0;
  int plannedExpenseCount = 0;

  void add({
    required String currencyCode,
    required int cents,
    required bool planned,
  }) {
    transactionCount++;
    if (planned) plannedExpenseCount++;
    centsByCurrency.update(
      currencyCode,
      (value) => value + cents,
      ifAbsent: () => cents,
    );
  }
}

final class _PlanDetail {
  const _PlanDetail({
    required this.kind,
    required this.sourceId,
    required this.label,
  });

  final CreditCardPaymentDetailKind kind;
  final String sourceId;
  final String label;
}
