import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

typedef RescheduleInstallmentsClock = DateTime Function();

final class RescheduleInstallmentsInput {
  const RescheduleInstallmentsInput({
    required this.installmentPlanId,
    required this.datesByTransactionId,
  });

  final String installmentPlanId;
  final Map<String, DateTime> datesByTransactionId;
}

final class RescheduleInstallmentsUseCase {
  RescheduleInstallmentsUseCase(
    this._transactionRepository, {
    this._statementRepository,
    RescheduleInstallmentsClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final TransactionRepository _transactionRepository;
  final CreditCardStatementRepository? _statementRepository;
  final RescheduleInstallmentsClock _clock;

  Future<List<Transaction>> getPlan(String installmentPlanId) async {
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(),
    );
    return List.unmodifiable(
      transactions
          .where(
            (item) =>
                !item.isDeleted && item.installmentPlanId == installmentPlanId,
          )
          .toList()
        ..sort(
          (left, right) =>
              left.installmentNumber!.compareTo(right.installmentNumber!),
        ),
    );
  }

  /// Ids of installments that may still be moved: dated after today and not
  /// already part of a cut credit card statement.
  Future<Set<String>> reschedulableIds(List<Transaction> installments) async {
    final today = _dateOnly(_clock());
    final statementLineIds = await _statementLineIds(installments);
    return {
      for (final item in installments)
        if (_dateOnly(item.transactionDate).isAfter(today) &&
            !statementLineIds.contains(item.id))
          item.id,
    };
  }

  Future<List<Transaction>> execute(RescheduleInstallmentsInput input) async {
    final installments = await getPlan(input.installmentPlanId);
    if (installments.isEmpty) {
      throw StateError('Installment plan not found.');
    }
    final allowedIds = await reschedulableIds(installments);
    final today = _dateOnly(_clock());
    for (final entry in input.datesByTransactionId.entries) {
      if (!allowedIds.contains(entry.key)) {
        throw ArgumentError.value(entry.key, 'transactionId');
      }
      if (!_dateOnly(entry.value).isAfter(today)) {
        throw ArgumentError.value(entry.value, 'date');
      }
    }

    final rescheduled = [
      for (final item in installments)
        switch (input.datesByTransactionId[item.id]) {
          final date? when !_isSameDay(date, item.transactionDate) => _withDate(
            item,
            date,
          ),
          _ => item,
        },
    ];
    for (var index = 1; index < rescheduled.length; index++) {
      if (!_dateOnly(
        rescheduled[index].transactionDate,
      ).isAfter(_dateOnly(rescheduled[index - 1].transactionDate))) {
        throw ArgumentError('Installment dates must be in ascending order.');
      }
    }

    final changed = [
      for (final (index, item) in rescheduled.indexed)
        if (!identical(item, installments[index])) item,
    ];
    for (final item in changed) {
      await _transactionRepository.update(item);
    }
    return List.unmodifiable(changed);
  }

  Future<Set<String>> _statementLineIds(List<Transaction> installments) async {
    final repository = _statementRepository;
    if (repository == null) return const {};
    final cardIds = installments.map((item) => item.creditCardId).nonNulls;
    return {
      for (final cardId in cardIds.toSet())
        for (final statement in await repository.getByCreditCardId(cardId))
          for (final line in statement.lines) line.transactionId,
    };
  }

  static Transaction _withDate(Transaction item, DateTime date) {
    return Transaction(
      id: item.id,
      accountId: item.accountId,
      creditCardId: item.creditCardId,
      amount: item.amount,
      transactionType: item.transactionType,
      categoryId: item.categoryId,
      merchant: item.merchant,
      note: item.note,
      transactionDate: _dateOnly(date),
      source: item.source,
      isDeleted: item.isDeleted,
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

  static bool _isSameDay(DateTime left, DateTime right) =>
      _dateOnly(left) == _dateOnly(right);
}
