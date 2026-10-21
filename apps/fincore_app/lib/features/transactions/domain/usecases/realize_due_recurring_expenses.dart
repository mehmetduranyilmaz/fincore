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
    final existingById = {for (final item in transactions) item.id: item};
    final today = _dateOnly(_clock());
    final dueTransactions = <Transaction>[];
    final redatedTransactions = <Transaction>[];

    for (final plan in plans) {
      final scheduledIds = <String>{};
      for (final dueDate in plan.dueDates) {
        final movementDate = plan.movementDate(dueDate);
        final transactionId = RecurringExpenseOccurrence.transactionId(
          planId: plan.id,
          dueDate: dueDate,
        );
        scheduledIds.add(transactionId);
        // The id keeps the due date, so an occurrence posted before its
        // movement offset was set is moved to its movement date in place.
        if (existingById[transactionId] case final existing?) {
          if (existing.source == TransactionSource.recurringPlan &&
              _dateOnly(existing.transactionDate) != movementDate) {
            redatedTransactions.add(_withDate(existing, movementDate));
          }
          continue;
        }
        if (movementDate.isAfter(today)) continue;

        // A due date that left the schedule and came back revives its
        // cancelled occurrence; the id is already taken in storage.
        final cancelled = await _transactionRepository.getById(transactionId);
        if (cancelled != null) {
          redatedTransactions.add(
            _withDate(cancelled, movementDate, isDeleted: false),
          );
          continue;
        }

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
            transactionDate: movementDate,
            source: TransactionSource.recurringPlan,
            isDeleted: false,
            customerId: plan.customerId,
            customerBalanceDelta: plan.customerId == null ? null : -plan.amount,
          ),
        );
      }

      // Occurrences whose due date is no longer in the edited schedule would
      // otherwise keep charging the ledger; cancel them.
      for (final item in transactions) {
        if (item.source == TransactionSource.recurringPlan &&
            RecurringExpenseOccurrence.belongsToPlan(item.id, plan.id) &&
            !scheduledIds.contains(item.id)) {
          redatedTransactions.add(
            _withDate(item, item.transactionDate, isDeleted: true),
          );
        }
      }
    }

    if (dueTransactions.isNotEmpty) {
      await _transactionRepository.createMany(dueTransactions);
    }
    for (final item in redatedTransactions) {
      await _transactionRepository.update(item);
    }
    return List.unmodifiable([...dueTransactions, ...redatedTransactions]);
  }

  static Transaction _withDate(
    Transaction item,
    DateTime date, {
    bool? isDeleted,
  }) {
    return Transaction(
      id: item.id,
      accountId: item.accountId,
      creditCardId: item.creditCardId,
      amount: item.amount,
      transactionType: item.transactionType,
      categoryId: item.categoryId,
      merchant: item.merchant,
      note: item.note,
      transactionDate: date,
      source: item.source,
      isDeleted: isDeleted ?? item.isDeleted,
      transferGroupId: item.transferGroupId,
      installmentPlanId: item.installmentPlanId,
      installmentNumber: item.installmentNumber,
      installmentCount: item.installmentCount,
      installmentTotalAmount: item.installmentTotalAmount,
      paymentGroupId: item.paymentGroupId,
      creditCardStatementId: item.creditCardStatementId,
      customerId: item.customerId,
      customerBalanceDelta: item.customerBalanceDelta,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
