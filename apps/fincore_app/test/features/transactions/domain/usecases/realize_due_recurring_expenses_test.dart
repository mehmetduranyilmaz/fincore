import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/repositories/recurring_expense_plan_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/realize_due_recurring_expenses.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'realizes only due occurrences once and updates customer debt',
    () async {
      var now = DateTime(2026, 8, 23);
      final transactionRepository = _TransactionRepository();
      final useCase = RealizeDueRecurringExpensesUseCase(
        _RecurringExpensePlanRepository([
          RecurringExpensePlan(
            id: 'education-plan',
            accountId: null,
            creditCardId: null,
            customerId: 'customer-1',
            amount: 500,
            description: 'Eğitim gideri',
            categoryId: 'education',
            currencyCode: 'TRY',
            firstDueDate: DateTime(2026, 8, 1),
            occurrenceCount: 5,
          ),
        ]),
        transactionRepository,
        clock: () => now,
      );

      final august = await useCase.execute();
      final duplicateAttempt = await useCase.execute();

      expect(august, hasLength(1));
      expect(duplicateAttempt, isEmpty);
      expect(transactionRepository.transactions, hasLength(1));
      expect(august.single.transactionDate, DateTime(2026, 8, 1));
      expect(august.single.customerId, 'customer-1');
      expect(august.single.customerBalanceDelta, -500);
      expect(august.single.source, TransactionSource.recurringPlan);
      expect(-3000 + august.single.customerBalanceDelta!, -3500);

      now = DateTime(2026, 9, 23);
      final september = await useCase.execute();

      expect(september, hasLength(1));
      expect(september.single.transactionDate, DateTime(2026, 9, 1));
      expect(transactionRepository.transactions, hasLength(2));
      expect(
        transactionRepository.transactions.map((item) => item.id).toSet(),
        hasLength(2),
      );
    },
  );

  test(
    'posts occurrences a month before their due date and re-dates old ones',
    () async {
      RecurringExpensePlan plan({required int movementMonthsBeforeDue}) =>
          RecurringExpensePlan(
            id: 'net-vip',
            accountId: null,
            creditCardId: null,
            customerId: 'net-vip-customer',
            amount: 14000,
            description: '14.000 × 10 TAKSİT',
            categoryId: null,
            currencyCode: 'TRY',
            firstDueDate: DateTime(2026, 9, 3),
            occurrenceCount: 10,
            movementMonthsBeforeDue: movementMonthsBeforeDue,
          );
      final plans = [plan(movementMonthsBeforeDue: 0)];
      final transactionRepository = _TransactionRepository();
      final useCase = RealizeDueRecurringExpensesUseCase(
        _RecurringExpensePlanRepository(plans),
        transactionRepository,
        clock: () => DateTime(2026, 10, 21),
      );

      await useCase.execute();
      expect(
        transactionRepository.transactions.map((item) => item.transactionDate),
        [DateTime(2026, 9, 3), DateTime(2026, 10, 3)],
      );

      plans[0] = plan(movementMonthsBeforeDue: 1);
      final changed = await useCase.execute();

      expect(changed, hasLength(3));
      final byId = {
        for (final item in transactionRepository.transactions) item.id: item,
      };
      expect(byId, hasLength(3));
      // Ids keep the due date; only the posting date moves a month earlier.
      expect(
        byId['recurring-expense-occurrence-net-vip-20260903']!.transactionDate,
        DateTime(2026, 8, 3),
      );
      expect(
        byId['recurring-expense-occurrence-net-vip-20261003']!.transactionDate,
        DateTime(2026, 9, 3),
      );
      expect(
        byId['recurring-expense-occurrence-net-vip-20261103']!.transactionDate,
        DateTime(2026, 10, 3),
      );
      expect(await useCase.execute(), isEmpty);
    },
  );

  test(
    'cancels occurrences that leave the schedule and revives them',
    () async {
      RecurringExpensePlan plan(DateTime firstDueDate) => RecurringExpensePlan(
        id: 'net-vip',
        accountId: null,
        creditCardId: null,
        customerId: 'net-vip-customer',
        amount: 14000,
        description: '14.000 × 10 TAKSİT',
        categoryId: null,
        currencyCode: 'TRY',
        firstDueDate: firstDueDate,
        occurrenceCount: 10,
      );
      final plans = [plan(DateTime(2026, 8, 3))];
      final transactionRepository = _TransactionRepository();
      final useCase = RealizeDueRecurringExpensesUseCase(
        _RecurringExpensePlanRepository(plans),
        transactionRepository,
        clock: () => DateTime(2026, 10, 21),
      );
      const augustId = 'recurring-expense-occurrence-net-vip-20260803';

      await useCase.execute();
      expect(transactionRepository.active, hasLength(3));

      plans[0] = plan(DateTime(2026, 9, 3));
      await useCase.execute();
      expect(
        transactionRepository.active.map((item) => item.id),
        isNot(contains(augustId)),
      );
      expect(transactionRepository.active, hasLength(2));

      plans[0] = plan(DateTime(2026, 8, 3));
      await useCase.execute();
      expect(
        transactionRepository.active.map((item) => item.id),
        contains(augustId),
      );
      expect(transactionRepository.active, hasLength(3));
    },
  );
}

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

final class _TransactionRepository implements TransactionRepository {
  final List<Transaction> transactions = [];

  List<Transaction> get active =>
      transactions.where((item) => !item.isDeleted).toList();

  @override
  Future<void> create(Transaction transaction) async {
    transactions.add(transaction);
  }

  @override
  Future<void> createMany(List<Transaction> transactions) async {
    this.transactions.addAll(transactions);
  }

  @override
  Future<Transaction?> getById(String transactionId) async {
    for (final transaction in transactions) {
      if (transaction.id == transactionId) return transaction;
    }
    return null;
  }

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async =>
      // Like local storage, listings leave out cancelled transactions.
      List.unmodifiable(active);

  @override
  Future<void> update(Transaction transaction) async {
    final index = transactions.indexWhere((item) => item.id == transaction.id);
    if (index >= 0) transactions[index] = transaction;
  }
}
