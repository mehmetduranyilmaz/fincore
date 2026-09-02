import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_payment_calendar.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/services/credit_card_period_calculator.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_occurrence.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
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
    this._statementRepository,
    CreditCardPaymentCalendarClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final CreditCardRepository _creditCardRepository;
  final TransactionRepository _transactionRepository;
  final RecurringExpensePlanRepository? _recurringExpensePlanRepository;
  final AccountRepository? _accountRepository;
  final CustomerRepository? _customerRepository;
  final CreditCardStatementRepository? _statementRepository;
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
    final firstVisibleMonth = DateTime(_clock().year - 100);
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(),
    );
    final statementsByCard = <String, List<CreditCardStatement>>{};
    if (_statementRepository != null) {
      for (final card in creditCards) {
        statementsByCard[card.id] = await _statementRepository
            .getByCreditCardId(card.id);
      }
    }
    final existingTransactionIds = transactions.map((item) => item.id).toSet();
    final monthBuckets = <(int, int), _MonthBucket>{};

    for (final transaction in transactions) {
      final creditCardId = transaction.creditCardId;
      final card = cardById[creditCardId];
      if (creditCardId == null ||
          card == null ||
          transaction.isDeleted ||
          transaction.source == TransactionSource.recurringPlan ||
          transaction.transactionType != TransactionType.expense) {
        continue;
      }

      final period = CreditCardPeriodCalculator.transactionPeriod(
        transactionId: transaction.id,
        transactionDate: transaction.transactionDate,
        statementDay: card.statementDay,
        statements: statementsByCard[card.id] ?? const [],
      );
      if (period.isBefore(firstVisibleMonth)) continue;
      final bucket = monthBuckets.putIfAbsent((
        period.year,
        period.month,
      ), _MonthBucket.new);
      bucket.add(
        currencyCode: card.currencyCode,
        amount: transaction.amount,
        detailKey: (CreditCardPaymentDetailKind.creditCard, card.id),
        detailLabel: _cardLabel(card),
        planned: false,
        paid: false,
      );
    }

    for (final card in creditCards) {
      for (final statement in statementsByCard[card.id] ?? const []) {
        final period = DateTime(
          statement.statementDate.year,
          statement.statementDate.month,
        );
        if (period.isBefore(firstVisibleMonth)) continue;
        final payments = transactions.where(
          (transaction) =>
              !transaction.isDeleted &&
              transaction.isCreditCardDebtPayment &&
              transaction.creditCardStatementId == statement.id,
        );
        final paidCents = payments.fold<int>(
          0,
          (sum, transaction) =>
              sum + InstallmentCalculator.toCents(transaction.amount.abs()),
        );
        final bucket = monthBuckets[(period.year, period.month)];
        bucket?.addPaid(
          currencyCode: card.currencyCode,
          cents: paidCents,
          detailKey: (CreditCardPaymentDetailKind.creditCard, card.id),
        );
      }
    }

    final recurringPlans =
        await _recurringExpensePlanRepository?.getPlans() ?? const [];
    final paidRecurringOccurrenceIds = _paidRecurringOccurrenceIds(
      recurringPlans,
      transactions,
      {
        for (final customer in customers)
          customer.id: InstallmentCalculator.toCents(
            customer.openingBalance < 0 ? -customer.openingBalance : 0,
          ),
      },
      _clock(),
    );
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
          // Posting the due occurrence is not proof of payment. Historical
          // customer payments are allocated FIFO to the customer's realized
          // recurring obligations, independently of the payment month.
          paid: paidRecurringOccurrenceIds.contains(
            RecurringExpenseOccurrence.transactionId(
              planId: plan.id,
              dueDate: dueDate,
            ),
          ),
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
              paidByCurrency: _toAmounts(detail.paidCentsByCurrency),
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
              paidByCurrency: _toAmounts(bucket.paidCentsByCurrency),
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

  static Set<String> _paidRecurringOccurrenceIds(
    List<RecurringExpensePlan> plans,
    List<Transaction> transactions,
    Map<String, int> openingPayableCentsByCustomer,
    DateTime now,
  ) {
    final obligationsByCustomer = <String, List<_RecurringObligation>>{};
    for (final plan in plans) {
      final customerId = plan.customerId;
      if (customerId == null) continue;
      for (final dueDate in plan.dueDates) {
        if (dueDate.isAfter(now)) break;
        obligationsByCustomer
            .putIfAbsent(customerId, () => [])
            .add(
              _RecurringObligation(
                id: RecurringExpenseOccurrence.transactionId(
                  planId: plan.id,
                  dueDate: dueDate,
                ),
                dueDate: dueDate,
                cents: InstallmentCalculator.toCents(plan.amount),
              ),
            );
      }
    }

    final result = <String>{};
    for (final entry in obligationsByCustomer.entries) {
      final obligations = entry.value
        ..sort((left, right) => left.dueDate.compareTo(right.dueDate));
      if (obligations.isEmpty) continue;
      var availablePaymentCents = transactions
          .where(
            (transaction) =>
                !transaction.isDeleted &&
                transaction.customerId == entry.key &&
                transaction.isCustomerPayment &&
                transaction.customerBalanceDelta! > 0 &&
                !transaction.transactionDate.isBefore(
                  obligations.first.dueDate,
                ),
          )
          .fold<int>(
            0,
            (sum, transaction) =>
                sum + InstallmentCalculator.toCents(transaction.amount.abs()),
          );
      // A customer payment settles the balance in chronological order. Consume
      // any payable opening balance before allocating it to recurring items;
      // otherwise a historical account-closing payment can incorrectly mark a
      // later month's occurrence as paid.
      final openingPayableCents =
          openingPayableCentsByCustomer[entry.key] ?? 0;
      availablePaymentCents = availablePaymentCents > openingPayableCents
          ? availablePaymentCents - openingPayableCents
          : 0;
      for (final obligation in obligations) {
        if (availablePaymentCents < obligation.cents) break;
        availablePaymentCents -= obligation.cents;
        result.add(obligation.id);
      }
    }
    return result;
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
  final Map<String, int> paidCentsByCurrency = {};
  final Map<(CreditCardPaymentDetailKind, String), _DetailBucket> details = {};
  int transactionCount = 0;
  int plannedExpenseCount = 0;

  void add({
    required String currencyCode,
    required double amount,
    required (CreditCardPaymentDetailKind, String) detailKey,
    required String detailLabel,
    required bool planned,
    required bool paid,
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
        .add(
          currencyCode: currencyCode,
          cents: cents,
          planned: planned,
          paid: paid,
        );
    if (paid) {
      paidCentsByCurrency.update(
        currencyCode,
        (value) => value + cents,
        ifAbsent: () => cents,
      );
    }
  }

  void addPaid({
    required String currencyCode,
    required int cents,
    required (CreditCardPaymentDetailKind, String) detailKey,
  }) {
    if (cents <= 0 || !details.containsKey(detailKey)) return;
    final capped = cents.clamp(0, centsByCurrency[currencyCode] ?? 0);
    paidCentsByCurrency.update(
      currencyCode,
      (value) => (value + capped).clamp(0, centsByCurrency[currencyCode] ?? 0),
      ifAbsent: () => capped,
    );
    details[detailKey]!.addPaid(currencyCode: currencyCode, cents: cents);
  }
}

final class _DetailBucket {
  _DetailBucket(this.label);

  final String label;
  final Map<String, int> centsByCurrency = {};
  final Map<String, int> paidCentsByCurrency = {};
  int transactionCount = 0;
  int plannedExpenseCount = 0;

  void add({
    required String currencyCode,
    required int cents,
    required bool planned,
    required bool paid,
  }) {
    transactionCount++;
    if (planned) plannedExpenseCount++;
    centsByCurrency.update(
      currencyCode,
      (value) => value + cents,
      ifAbsent: () => cents,
    );
    if (paid) {
      paidCentsByCurrency.update(
        currencyCode,
        (value) => value + cents,
        ifAbsent: () => cents,
      );
    }
  }

  void addPaid({required String currencyCode, required int cents}) {
    final total = centsByCurrency[currencyCode] ?? 0;
    if (cents <= 0 || total <= 0) return;
    paidCentsByCurrency.update(
      currencyCode,
      (value) => (value + cents).clamp(0, total),
      ifAbsent: () => cents.clamp(0, total),
    );
  }
}

final class _RecurringObligation {
  const _RecurringObligation({
    required this.id,
    required this.dueDate,
    required this.cents,
  });

  final String id;
  final DateTime dueDate;
  final int cents;
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
