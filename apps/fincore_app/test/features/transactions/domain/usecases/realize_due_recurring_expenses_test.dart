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
      List.unmodifiable(transactions);

  @override
  Future<void> update(Transaction transaction) async {}
}
