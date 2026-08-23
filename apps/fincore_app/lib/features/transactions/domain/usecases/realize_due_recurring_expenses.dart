import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_occurrence.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/recurring_expense_plan_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

typedef RecurringExpenseRealizationClock = DateTime Function();

final class RealizeDueRecurringExpensesUseCase {
  RealizeDueRecurringExpensesUseCase(
    this._planRepository,
    this._transactionRepository, {
    RecurringExpenseRealizationClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final RecurringExpensePlanRepository _planRepository;
  final TransactionRepository _transactionRepository;
  final RecurringExpenseRealizationClock _clock;

  Future<List<Transaction>>? _inFlight;

  Future<List<Transaction>> execute() {
    final active = _inFlight;
    if (active != null) return active;

    late final Future<List<Transaction>> tracked;
    tracked = _execute().whenComplete(() {
      if (identical(_inFlight, tracked)) _inFlight = null;
    });
    _inFlight = tracked;
    return tracked;
  }

  Future<List<Transaction>> _execute() async {
    final plans = await _planRepository.getPlans();
    if (plans.isEmpty) return const [];

    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(),
    );
    final existingIds = transactions.map((item) => item.id).toSet();
    final today = _dateOnly(_clock());
    final dueTransactions = <Transaction>[];

    for (final plan in plans) {
      for (final dueDate in plan.dueDates) {
        if (dueDate.isAfter(today)) break;
        final transactionId = RecurringExpenseOccurrence.transactionId(
          planId: plan.id,
          dueDate: dueDate,
        );
        if (!existingIds.add(transactionId)) continue;

        dueTransactions.add(
          Transaction(
            id: transactionId,
            accountId: plan.accountId,
            creditCardId: plan.creditCardId,
            amount: plan.amount,
            transactionType: TransactionType.expense,
            categoryId: plan.categoryId,
            merchant: plan.description,
            note: 'Tekrarlayan gider planından otomatik oluşturuldu.',
            transactionDate: dueDate,
            source: TransactionSource.recurringPlan,
            isDeleted: false,
            customerId: plan.customerId,
            customerBalanceDelta: plan.customerId == null ? null : -plan.amount,
          ),
        );
      }
    }

    if (dueTransactions.isNotEmpty) {
      await _transactionRepository.createMany(dueTransactions);
    }
    return List.unmodifiable(dueTransactions);
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
