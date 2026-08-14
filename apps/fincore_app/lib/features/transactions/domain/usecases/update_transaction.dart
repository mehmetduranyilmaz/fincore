import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
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
    this.customerRepository,
    UpdateTransactionClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final TransactionRepository _repository;
  final TransactionCategoryValidator? categoryValidator;
  final CustomerRepository? customerRepository;
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
    await _validateCustomer(input.customerId);

    final isCustomerCreditExpense =
        current.transactionType == TransactionType.expense &&
        input.customerId != null;

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
      paymentGroupId: current.paymentGroupId,
      creditCardStatementId: current.creditCardStatementId,
      customerId: input.customerId,
      customerBalanceDelta: isCustomerCreditExpense ? -input.amount : null,
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

  Future<void> _validateCustomer(String? customerId) async {
    if (customerId == null) return;
    final repository = customerRepository;
    if (repository == null) {
      throw StateError('Customer repository is required.');
    }
    final customer = await repository.getById(customerId);
    if (customer == null || customer.isArchived) {
      throw ArgumentError.value(customerId, 'customerId');
    }
  }

  void _validate(UpdateTransactionInput input, TransactionType type) {
    ManualTransactionValidator.validateAmount(input.amount);
    ManualTransactionValidator.validateDescription(input.description);
    ManualTransactionValidator.validateDate(input.transactionDate, _clock());
    final sourceCount = [
      input.accountId,
      input.creditCardId,
      input.customerId,
    ].nonNulls.length;
    if (sourceCount != 1) {
      throw ArgumentError(
        'Exactly one account, credit card, or open-account customer is required.',
      );
    }

    if (type == TransactionType.income &&
        (input.creditCardId != null || input.customerId != null)) {
      throw ArgumentError('Income must use an account.');
    }
  }
}
