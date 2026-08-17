import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_manual_expense_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/installment_transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/services/transaction_category_validator.dart';
import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';
import 'package:fincore_app/features/transactions/domain/usecases/manual_transaction_validator.dart';

typedef TransactionClock = DateTime Function();
typedef TransactionIdGenerator = String Function();

final class CreateManualExpenseUseCase {
  CreateManualExpenseUseCase(
    this._repository, {
    this.installmentRepository,
    this.categoryValidator,
    this.customerRepository,
    TransactionClock? clock,
    TransactionIdGenerator? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _generateId;

  final TransactionRepository _repository;
  final InstallmentTransactionRepository? installmentRepository;
  final TransactionCategoryValidator? categoryValidator;
  final CustomerRepository? customerRepository;
  final TransactionClock _clock;
  final TransactionIdGenerator _idGenerator;

  Future<Transaction> execute(CreateManualExpenseInput input) async {
    _validate(input);
    await _validateCategory(input.categoryId);
    await _validateCustomer(input.customerId);

    final transactionId = _idGenerator();
    final installmentAmounts = input.installmentAmounts.isEmpty
        ? [input.amount]
        : input.installmentAmounts;
    final isInstallment = installmentAmounts.length > 1;
    final installmentPlanId = isInstallment ? '$transactionId-plan' : null;
    final transactions = [
      for (final (index, amount) in installmentAmounts.indexed)
        Transaction(
          id: index == 0
              ? transactionId
              : '$transactionId-installment-${index + 1}',
          accountId: input.accountId,
          creditCardId: input.creditCardId,
          amount: amount,
          transactionType: TransactionType.expense,
          categoryId: input.categoryId,
          merchant: input.description.trim(),
          note: null,
          transactionDate: isInstallment
              ? InstallmentCalculator.installmentDate(
                  input.transactionDate,
                  index,
                )
              : input.transactionDate,
          source: TransactionSource.manual,
          isDeleted: false,
          customerId: input.customerId,
          customerBalanceDelta: input.customerId == null ? null : -amount,
          installmentPlanId: installmentPlanId,
          installmentNumber: isInstallment ? index + 1 : null,
          installmentCount: isInstallment ? installmentAmounts.length : null,
          installmentTotalAmount: isInstallment ? input.amount : null,
        ),
    ];

    if (isInstallment) {
      final repository = installmentRepository;
      if (repository == null) {
        throw StateError('Installment repository is required.');
      }
      await repository.createPlan(transactions);
    } else {
      await _repository.create(transactions.single);
    }

    return transactions.first;
  }

  Future<void> _validateCategory(String? categoryId) async {
    if (categoryId == null || categoryValidator == null) {
      return;
    }
    await categoryValidator!.validate(
      categoryId: categoryId,
      transactionType: TransactionType.expense,
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

  void _validate(CreateManualExpenseInput input) {
    ManualTransactionValidator.validateAmount(input.amount);
    ManualTransactionValidator.validateDescription(input.description);

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

    ManualTransactionValidator.validateDate(input.transactionDate, _clock());

    if (input.installmentAmounts.isEmpty) {
      return;
    }
    if (input.installmentAmounts.length == 1) {
      if (InstallmentCalculator.toCents(input.installmentAmounts.single) !=
          InstallmentCalculator.toCents(input.amount)) {
        throw ArgumentError.value(
          input.installmentAmounts,
          'installmentAmounts',
        );
      }
      return;
    }
    if (input.creditCardId == null && input.customerId == null) {
      throw ArgumentError('Installments require a credit card or customer.');
    }
    InstallmentCalculator.validateCustomAmounts(
      input.amount,
      input.installmentAmounts,
    );
  }

  static String _generateId() {
    return 'manual-expense-${DateTime.now().microsecondsSinceEpoch}';
  }
}
