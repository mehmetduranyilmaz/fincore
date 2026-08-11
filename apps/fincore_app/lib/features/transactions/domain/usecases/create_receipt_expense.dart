import 'package:fincore_app/features/transactions/domain/entities/create_receipt_expense_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/installment_transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/services/transaction_category_validator.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_manual_expense.dart';
import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';
import 'package:fincore_app/features/transactions/domain/usecases/manual_transaction_validator.dart';

typedef InstallmentPlanIdGenerator = String Function();
typedef InstallmentTransactionIdGenerator = String Function(int index);

final class CreateReceiptExpenseUseCase {
  CreateReceiptExpenseUseCase(
    this._repository, {
    this.categoryValidator,
    TransactionClock? clock,
    InstallmentPlanIdGenerator? planIdGenerator,
    InstallmentTransactionIdGenerator? transactionIdGenerator,
  }) : _clock = clock ?? DateTime.now,
       _planIdGenerator = planIdGenerator ?? _generatePlanId,
       _transactionIdGenerator =
           transactionIdGenerator ?? _generateTransactionId;

  final InstallmentTransactionRepository _repository;
  final TransactionCategoryValidator? categoryValidator;
  final TransactionClock _clock;
  final InstallmentPlanIdGenerator _planIdGenerator;
  final InstallmentTransactionIdGenerator _transactionIdGenerator;

  Future<List<Transaction>> execute(CreateReceiptExpenseInput input) async {
    _validate(input);
    await _validateCategory(input.categoryId);

    final installmentCount = input.installmentAmounts.length;
    final isInstallment = installmentCount > 1;
    final planId = isInstallment ? _planIdGenerator() : null;
    final transactions = [
      for (final (index, amount) in input.installmentAmounts.indexed)
        Transaction(
          id: _transactionIdGenerator(index),
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
          source: TransactionSource.receiptScan,
          isDeleted: false,
          installmentPlanId: planId,
          installmentNumber: isInstallment ? index + 1 : null,
          installmentCount: isInstallment ? installmentCount : null,
          installmentTotalAmount: isInstallment ? input.totalAmount : null,
        ),
    ];

    await _repository.createPlan(transactions);
    return List.unmodifiable(transactions);
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

  void _validate(CreateReceiptExpenseInput input) {
    ManualTransactionValidator.validateAmount(input.totalAmount);
    ManualTransactionValidator.validateDescription(input.description);
    ManualTransactionValidator.validateDate(input.transactionDate, _clock());
    Transaction.validateSource(
      accountId: input.accountId,
      creditCardId: input.creditCardId,
    );
    if (input.creditCardId == null || input.accountId != null) {
      throw ArgumentError.value(input.creditCardId, 'creditCardId');
    }

    if (input.installmentAmounts.length == 1) {
      if (InstallmentCalculator.toCents(input.installmentAmounts.single) !=
          InstallmentCalculator.toCents(input.totalAmount)) {
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
      input.totalAmount,
      input.installmentAmounts,
    );
  }

  static String _generatePlanId() {
    return 'installment-plan-${DateTime.now().microsecondsSinceEpoch}';
  }

  static String _generateTransactionId(int index) {
    return 'receipt-expense-${DateTime.now().microsecondsSinceEpoch}-$index';
  }
}
