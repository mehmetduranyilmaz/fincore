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
    TransactionClock? clock,
    TransactionIdGenerator? idGenerator,
  }) : _clock = clock ?? DateTime.now,
       _idGenerator = idGenerator ?? _generateId;

  final TransactionRepository _repository;
  final InstallmentTransactionRepository? installmentRepository;
  final TransactionCategoryValidator? categoryValidator;
  final TransactionClock _clock;
  final TransactionIdGenerator _idGenerator;

  Future<Transaction> execute(CreateManualExpenseInput input) async {
    _validate(input);
    await _validateCategory(input.categoryId);

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

  void _validate(CreateManualExpenseInput input) {
    ManualTransactionValidator.validateAmount(input.amount);
    ManualTransactionValidator.validateDescription(input.description);

    Transaction.validateSource(
      accountId: input.accountId,
      creditCardId: input.creditCardId,
    );

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
    if (input.creditCardId == null) {
      throw ArgumentError.value(input.creditCardId, 'creditCardId');
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
