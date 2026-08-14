import 'package:fincore_app/features/budgets/domain/entities/budget.dart';
import 'package:fincore_app/features/budgets/domain/entities/budget_progress.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class CalculateBudgetProgressUseCase {
  const CalculateBudgetProgressUseCase(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  Future<BudgetProgress> execute(Budget budget) async {
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(
        transactionTypes: const {TransactionType.expense},
        startDate: DateTime(budget.year, budget.month),
        endDate: DateTime(budget.year, budget.month + 1, 0),
      ),
    );
    var spentAmount = 0.0;

    for (final transaction in transactions) {
      final date = transaction.transactionDate;
      if (!transaction.isDeleted &&
          transaction.transactionType == TransactionType.expense &&
          transaction.isActualExpense &&
          transaction.categoryId == budget.categoryId &&
          date.month == budget.month &&
          date.year == budget.year) {
        spentAmount += transaction.amount.abs();
      }
    }

    return BudgetProgress.calculate(
      budgetAmount: budget.amount,
      spentAmount: spentAmount,
    );
  }
}
