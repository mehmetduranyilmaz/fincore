import 'package:fincore_app/features/accounts/domain/entities/account_balance.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';

final class CalculateAccountBalanceUseCase {
  const CalculateAccountBalanceUseCase(
    this._transactionRepository, {
    this.accountRepository,
  });

  final TransactionRepository _transactionRepository;
  final AccountRepository? accountRepository;

  Future<AccountBalance> execute(String accountId) async {
    if (accountId.trim().isEmpty) {
      throw ArgumentError.value(accountId, 'accountId');
    }

    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(accountId: accountId),
    );
    final accounts = await accountRepository?.getAccounts();
    final openingBalance =
        accounts
            ?.where((item) => item.id == accountId)
            .firstOrNull
            ?.openingBalance ??
        0.0;
    var currentBalance = openingBalance;
    var totalIncome = 0.0;
    var totalExpense = 0.0;

    for (final transaction in transactions) {
      if (transaction.isDeleted || transaction.accountId != accountId) {
        continue;
      }

      switch (transaction.transactionType) {
        case TransactionType.income:
          final amount = transaction.amount.abs();
          currentBalance += amount;
          totalIncome += amount;
        case TransactionType.expense:
          final amount = transaction.amount.abs();
          currentBalance -= amount;
          totalExpense += amount;
        case TransactionType.transfer:
          currentBalance += transaction.amount;
          if (transaction.amount >= 0) {
            totalIncome += transaction.amount;
          } else {
            totalExpense += transaction.amount.abs();
          }
      }
    }

    return AccountBalance(
      currentBalance: currentBalance,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }
}
