import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_payment_calendar.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_occurrence.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/recurring_expense_plan_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups current and future card expenses by month and year', () async {
    final useCase = GetCreditCardPaymentCalendarUseCase(
      const _CreditCardRepository(),
      _TransactionRepository([
        _expense('oct-try', 'try-card', 100, DateTime(2025, 10, 10)),
        _expense('oct-usd', 'usd-card', 20, DateTime(2025, 10, 20)),
        _expense('nov-try', 'try-card', 50, DateTime(2025, 11, 10)),
        _expense('dec-try', 'try-card', 25, DateTime(2025, 12, 10)),
        _expense('jan-try', 'try-card', 10, DateTime(2026, 1, 10)),
        _expense('past', 'try-card', 999, DateTime(2025, 9, 30)),
        _expense(
          'deleted',
          'try-card',
          999,
          DateTime(2025, 11, 1),
          isDeleted: true,
        ),
        _expense('account', null, 999, DateTime(2025, 11, 1)),
      ]),
      recurringExpensePlanRepository: _RecurringExpensePlanRepository([
        _aidatPlan,
      ]),
      accountRepository: const _AccountRepository(),
      customerRepository: const _CustomerRepository(),
      clock: () => DateTime(2025, 10, 8),
    );

    final calendar = await useCase.execute();

    expect(calendar.years.map((year) => year.year), [2025, 2026]);
    final year2025 = calendar.years.first;
    expect(year2025.months.map((month) => month.periodLabel), [
      '2025-10',
      '2025-11',
      '2025-12',
    ]);
    expect(year2025.months.first.totalsByCurrency, {'TRY': 100, 'USD': 20});
    expect(year2025.months.first.transactionCount, 2);
    expect(year2025.months[1].totalsByCurrency, {'TRY': 90});
    expect(year2025.months[1].confirmedTransactionCount, 1);
    expect(year2025.months[1].plannedExpenseCount, 1);
    expect(year2025.months.first.details, hasLength(2));
    expect(
      year2025.months[1].details.map((detail) => detail.label),
      containsAll(['Kredi Kartı • Akbank Axess • ****0349', 'Hesap • TL Kasa']),
    );
    expect(year2025.totalsByCurrency, {'TRY': 255, 'USD': 20});
    expect(calendar.years.last.months.single.periodLabel, '2026-01');
    expect(calendar.years.last.totalsByCurrency, {'TRY': 50});
  });

  test('includes customer payments made by credit card', () async {
    final useCase = GetCreditCardPaymentCalendarUseCase(
      const _CreditCardRepository(),
      _TransactionRepository([
        _expense(
          'customer-payment',
          'try-card',
          22750,
          DateTime(2025, 10, 10),
          paymentGroupId: 'customer-payment-group',
          customerId: 'customer-1',
          customerBalanceDelta: 22750,
        ),
      ]),
      clock: () => DateTime(2025, 10, 8),
    );

    final calendar = await useCase.execute();

    final month = calendar.years.single.months.single;
    expect(month.totalsByCurrency, {'TRY': 22750});
    expect(month.transactionCount, 1);
    expect(month.details.single.label, 'Kredi Kartı • Akbank Axess • ****0349');
  });

  test(
    'shows a realized customer plan once as confirmed and future as planned',
    () async {
      final plan = RecurringExpensePlan(
        id: 'customer-plan',
        accountId: null,
        creditCardId: null,
        customerId: 'customer-1',
        amount: 500,
        description: 'Eğitim gideri',
        categoryId: 'education',
        currencyCode: 'TRY',
        firstDueDate: DateTime(2025, 10, 5),
        occurrenceCount: 2,
      );
      final realizedId = RecurringExpenseOccurrence.transactionId(
        planId: plan.id,
        dueDate: DateTime(2025, 10, 5),
      );
      final useCase = GetCreditCardPaymentCalendarUseCase(
        const _CreditCardRepository(),
        _TransactionRepository([
          Transaction(
            id: realizedId,
            accountId: null,
            creditCardId: null,
            amount: 500,
            transactionType: TransactionType.expense,
            categoryId: 'education',
            merchant: 'Eğitim gideri',
            note: null,
            transactionDate: DateTime(2025, 10, 5),
            source: TransactionSource.recurringPlan,
            isDeleted: false,
            customerId: 'customer-1',
            customerBalanceDelta: -500,
          ),
        ]),
        recurringExpensePlanRepository: _RecurringExpensePlanRepository([plan]),
        customerRepository: const _CustomerRepository(),
        clock: () => DateTime(2025, 10, 8),
      );

      final calendar = await useCase.execute();
      final october = calendar.years.single.months.first;
      final november = calendar.years.single.months.last;

      expect(october.totalsByCurrency, {'TRY': 500});
      expect(october.confirmedTransactionCount, 1);
      expect(october.plannedExpenseCount, 0);
      expect(october.details.single.label, 'Müşteri • Mehmet Eğitim');
      expect(october.details.single.confirmedTransactionCount, 1);
      expect(november.plannedExpenseCount, 1);
      expect(november.details.single.plannedExpenseCount, 1);
    },
  );
}

final class _AccountRepository implements AccountRepository {
  const _AccountRepository();

  @override
  Future<List<Account>> getAccounts() async => const [
    Account(
      id: 'account-1',
      name: 'TL Kasa',
      type: AccountType.cash,
      currencyCode: 'TRY',
      isArchived: false,
    ),
  ];
}

final class _CustomerRepository implements CustomerRepository {
  const _CustomerRepository();

  static const customer = Customer(
    id: 'customer-1',
    name: 'Mehmet Eğitim',
    openingBalance: -3000,
    currencyCode: 'TRY',
    isArchived: false,
  );

  @override
  Future<void> archive(String customerId) async {}

  @override
  Future<void> create(Customer customer) async {}

  @override
  Future<Customer?> getById(String customerId) async =>
      customerId == customer.id ? customer : null;

  @override
  Future<List<Customer>> getCustomers() async => const [customer];

  @override
  Future<void> update(Customer customer) async {}
}

final _aidatPlan = RecurringExpensePlan(
  id: 'aidat-plan',
  accountId: 'account-1',
  creditCardId: null,
  customerId: null,
  amount: 40,
  description: 'Bina aidatı',
  categoryId: 'category-aidat',
  currencyCode: 'TRY',
  firstDueDate: DateTime(2025, 11, 5),
  occurrenceCount: 3,
);

final class _RecurringExpensePlanRepository
    implements RecurringExpensePlanRepository {
  const _RecurringExpensePlanRepository(this.plans);

  final List<RecurringExpensePlan> plans;

  @override
  Future<void> create(RecurringExpensePlan plan) async {}

  @override
  Future<void> delete(String planId) async {}

  @override
  Future<List<RecurringExpensePlan>> getPlans() async => plans;

  @override
  Future<void> update(RecurringExpensePlan plan) async {}
}

Transaction _expense(
  String id,
  String? creditCardId,
  double amount,
  DateTime date, {
  bool isDeleted = false,
  String? paymentGroupId,
  String? customerId,
  double? customerBalanceDelta,
}) {
  return Transaction(
    id: id,
    accountId: creditCardId == null ? 'account-1' : null,
    creditCardId: creditCardId,
    amount: amount,
    transactionType: TransactionType.expense,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: date,
    source: TransactionSource.manual,
    isDeleted: isDeleted,
    paymentGroupId: paymentGroupId,
    customerId: customerId,
    customerBalanceDelta: customerBalanceDelta,
  );
}

final class _CreditCardRepository implements CreditCardRepository {
  const _CreditCardRepository();

  @override
  Future<List<CreditCard>> getCreditCards() async => const [
    CreditCard(
      id: 'try-card',
      bankName: 'Akbank',
      cardName: 'Axess',
      lastFourDigits: '0349',
      creditLimit: 10000,
      statementDay: 20,
      dueDay: 30,
      currencyCode: 'TRY',
      isArchived: false,
    ),
    CreditCard(
      id: 'usd-card',
      bankName: 'Akbank',
      cardName: 'USD Kart',
      lastFourDigits: '9876',
      creditLimit: 10000,
      statementDay: 20,
      dueDay: 30,
      currencyCode: 'USD',
      isArchived: false,
    ),
  ];
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.transactions);

  final List<Transaction> transactions;

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async =>
      transactions;

  @override
  Future<void> update(Transaction transaction) async {}
}
