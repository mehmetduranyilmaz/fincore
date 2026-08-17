import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_recurring_expense_plan_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/repositories/recurring_expense_plan_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/usecases/update_recurring_expense_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates one plan and calculates every monthly due date', () async {
    final repository = _PlanRepository();
    final useCase = CreateRecurringExpensePlanUseCase(
      repository,
      const _AccountRepository(),
      const _CreditCardRepository(),
      const _CustomerRepository(),
      clock: () => DateTime(2026, 8, 17),
      idGenerator: () => 'plan-1',
    );

    final plan = await useCase.execute(
      CreateRecurringExpensePlanInput(
        accountId: 'account-1',
        creditCardId: null,
        customerId: null,
        amount: 2500,
        description: ' Bina aidatı ',
        categoryId: 'aidat',
        firstDueDate: DateTime(2026, 8, 31),
        occurrenceCount: 6,
      ),
    );

    expect(plan.description, 'Bina aidatı');
    expect(plan.currencyCode, 'TRY');
    expect(plan.dueDates, [
      DateTime(2026, 8, 31),
      DateTime(2026, 9, 30),
      DateTime(2026, 10, 31),
      DateTime(2026, 11, 30),
      DateTime(2026, 12, 31),
      DateTime(2027, 1, 31),
    ]);
    expect(repository.plans, [plan]);
  });

  test('accepts the first day of the current month', () async {
    final repository = _PlanRepository();
    final useCase = CreateRecurringExpensePlanUseCase(
      repository,
      const _AccountRepository(),
      const _CreditCardRepository(),
      const _CustomerRepository(),
      clock: () => DateTime(2026, 8, 17),
      idGenerator: () => 'plan-current-month',
    );

    final plan = await useCase.execute(
      CreateRecurringExpensePlanInput(
        accountId: 'account-1',
        creditCardId: null,
        customerId: null,
        amount: 2500,
        description: 'Bina aidatı',
        categoryId: null,
        firstDueDate: DateTime(2026, 8),
        occurrenceCount: 6,
      ),
    );

    expect(plan.firstDueDate, DateTime(2026, 8));
  });

  test('rejects a recurring plan before the current month', () {
    final useCase = CreateRecurringExpensePlanUseCase(
      _PlanRepository(),
      const _AccountRepository(),
      const _CreditCardRepository(),
      const _CustomerRepository(),
      clock: () => DateTime(2026, 8, 17),
    );

    expect(
      () => useCase.execute(
        CreateRecurringExpensePlanInput(
          accountId: 'account-1',
          creditCardId: null,
          customerId: null,
          amount: 2500,
          description: 'Bina aidatı',
          categoryId: null,
          firstDueDate: DateTime(2026, 7, 31),
          occurrenceCount: 6,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('updates an existing plan without changing its identity', () async {
    final repository = _PlanRepository();
    repository.plans.add(
      RecurringExpensePlan(
        id: 'plan-1',
        accountId: 'account-1',
        creditCardId: null,
        customerId: null,
        amount: 1000,
        description: 'Eski aidat',
        categoryId: null,
        currencyCode: 'TRY',
        firstDueDate: DateTime(2026, 8),
        occurrenceCount: 6,
      ),
    );
    final useCase = UpdateRecurringExpensePlanUseCase(
      repository,
      const _AccountRepository(),
      const _CreditCardRepository(),
      const _CustomerRepository(),
    );

    final updated = await useCase.execute(
      'plan-1',
      CreateRecurringExpensePlanInput(
        accountId: 'account-1',
        creditCardId: null,
        customerId: null,
        amount: 1250,
        description: ' Güncel aidat ',
        categoryId: null,
        firstDueDate: DateTime(2026, 7),
        occurrenceCount: 12,
      ),
    );

    expect(updated.id, 'plan-1');
    expect(updated.description, 'Güncel aidat');
    expect(updated.amount, 1250);
    expect(updated.firstDueDate, DateTime(2026, 7));
    expect(repository.plans.single, updated);
  });
}

final class _PlanRepository implements RecurringExpensePlanRepository {
  final List<RecurringExpensePlan> plans = [];

  @override
  Future<void> create(RecurringExpensePlan plan) async => plans.add(plan);

  @override
  Future<void> delete(String planId) async =>
      plans.removeWhere((item) => item.id == planId);

  @override
  Future<List<RecurringExpensePlan>> getPlans() async => plans;

  @override
  Future<void> update(RecurringExpensePlan plan) async {
    final index = plans.indexWhere((item) => item.id == plan.id);
    plans[index] = plan;
  }
}

final class _AccountRepository implements AccountRepository {
  const _AccountRepository();

  @override
  Future<List<Account>> getAccounts() async => const [
    Account(
      id: 'account-1',
      name: 'Banka',
      type: AccountType.checking,
      currencyCode: 'TRY',
      isArchived: false,
    ),
  ];
}

final class _CreditCardRepository implements CreditCardRepository {
  const _CreditCardRepository();

  @override
  Future<List<CreditCard>> getCreditCards() async => const [];
}

final class _CustomerRepository implements CustomerRepository {
  const _CustomerRepository();

  @override
  Future<void> archive(String customerId) async {}

  @override
  Future<void> create(Customer customer) async {}

  @override
  Future<Customer?> getById(String customerId) async => null;

  @override
  Future<List<Customer>> getCustomers() async => const [];

  @override
  Future<void> update(Customer customer) async {}
}
