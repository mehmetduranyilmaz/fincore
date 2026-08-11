import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/installment_transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_receipt_expense.dart';
import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';

final class ConvertExpenseToInstallmentsInput {
  const ConvertExpenseToInstallmentsInput({
    required this.transactionId,
    required this.installmentAmounts,
  });

  final String transactionId;
  final List<double> installmentAmounts;
}

final class ConvertExpenseToInstallmentsUseCase {
  ConvertExpenseToInstallmentsUseCase(
    this._transactionRepository,
    this._installmentRepository, {
    InstallmentPlanIdGenerator? planIdGenerator,
    InstallmentTransactionIdGenerator? transactionIdGenerator,
  }) : _planIdGenerator = planIdGenerator ?? _generatePlanId,
       _transactionIdGenerator =
           transactionIdGenerator ?? _generateTransactionId;

  final TransactionRepository _transactionRepository;
  final InstallmentTransactionRepository _installmentRepository;
  final InstallmentPlanIdGenerator _planIdGenerator;
  final InstallmentTransactionIdGenerator _transactionIdGenerator;

  Future<List<Transaction>> execute(
    ConvertExpenseToInstallmentsInput input,
  ) async {
    final original = await _transactionRepository.getById(input.transactionId);
    if (original == null) {
      throw StateError('Transaction not found.');
    }
    if (!original.canConvertToInstallments) {
      throw UnsupportedError('Transaction cannot be converted.');
    }
    InstallmentCalculator.validateCustomAmounts(
      original.amount,
      input.installmentAmounts,
    );

    final planId = _planIdGenerator();
    final count = input.installmentAmounts.length;
    final installments = [
      for (final (index, amount) in input.installmentAmounts.indexed)
        Transaction(
          id: index == 0 ? original.id : _transactionIdGenerator(index),
          accountId: original.accountId,
          creditCardId: original.creditCardId,
          amount: amount,
          transactionType: original.transactionType,
          categoryId: original.categoryId,
          merchant: original.merchant,
          note: original.note,
          transactionDate: InstallmentCalculator.installmentDate(
            original.transactionDate,
            index,
          ),
          source: original.source,
          isDeleted: original.isDeleted,
          transferGroupId: original.transferGroupId,
          installmentPlanId: planId,
          installmentNumber: index + 1,
          installmentCount: count,
          installmentTotalAmount: original.amount,
        ),
    ];

    await _installmentRepository.replaceWithPlan(installments);
    return List.unmodifiable(installments);
  }

  static String _generatePlanId() {
    return 'installment-plan-${DateTime.now().microsecondsSinceEpoch}';
  }

  static String _generateTransactionId(int index) {
    return 'installment-${DateTime.now().microsecondsSinceEpoch}-$index';
  }
}
