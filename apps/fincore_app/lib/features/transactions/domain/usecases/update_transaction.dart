import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/entities/update_transaction_input.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/services/transaction_category_validator.dart';
import 'package:fincore_app/features/transactions/domain/usecases/manual_transaction_validator.dart';

typedef UpdateTransactionClock = DateTime Function();

final class UpdateTransactionUseCase {
  UpdateTransactionUseCase(
    this._repository, {
    this.categoryValidator,
    UpdateTransactionClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final TransactionRepository _repository;
  final TransactionCategoryValidator? categoryValidator;
  final UpdateTransactionClock _clock;

  Future<Transaction> execute(UpdateTransactionInput input) async {
    final current = await _repository.getById(input.transactionId);
    if (current == null) {
      throw StateError('Transaction not found.');
    }
    if (!current.isEditable) {
      throw UnsupportedError('Only manual income and expense can be edited.');
    }

    _validate(input, current.transactionType);
    await _validateCategory(input.categoryId, current.transactionType);

    final updated = Transaction(
      id: current.id,
      accountId: input.accountId,
      creditCardId: input.creditCardId,
      amount: input.amount,
      transactionType: current.transactionType,
      categoryId: input.categoryId,
      merchant: input.description.trim(),
      note: current.note,
      transactionDate: input.transactionDate,
      source: current.source,
      isDeleted: current.isDeleted,
      transferGroupId: current.transferGroupId,
      installmentPlanId: current.installmentPlanId,
      installmentNumber: current.installmentNumber,
      installmentCount: current.installmentCount,
      installmentTotalAmount: current.installmentTotalAmount,
    );

    await _repository.update(updated);

    return updated;
  }

  Future<void> _validateCategory(
    String? categoryId,
    TransactionType transactionType,
  ) async {
    if (categoryId == null || categoryValidator == null) {
      return;
    }
    await categoryValidator!.validate(
      categoryId: categoryId,
      transactionType: transactionType,
    );
  }

  void _validate(UpdateTransactionInput input, TransactionType type) {
    ManualTransactionValidator.validateAmount(input.amount);
    ManualTransactionValidator.validateDescription(input.description);
    ManualTransactionValidator.validateDate(input.transactionDate, _clock());
    Transaction.validateSource(
      accountId: input.accountId,
      creditCardId: input.creditCardId,
    );

    if (type == TransactionType.income && input.creditCardId != null) {
      throw ArgumentError.value(input.creditCardId, 'creditCardId');
    }
  }
}
