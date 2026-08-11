import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/domain/usecases/calculate_account_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/calculate_credit_card_balance.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

typedef DashboardClock = DateTime Function();

final class CalculateDashboardSummaryUseCase {
  CalculateDashboardSummaryUseCase(
    this._accountRepository,
    this._creditCardRepository,
    this._transactionRepository,
    this._calculateAccountBalance,
    this._calculateCreditCardBalance, {
    DashboardClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final AccountRepository _accountRepository;
  final CreditCardRepository _creditCardRepository;
  final TransactionRepository _transactionRepository;
  final CalculateAccountBalanceUseCase _calculateAccountBalance;
  final CalculateCreditCardBalanceUseCase _calculateCreditCardBalance;
  final DashboardClock _clock;

  Future<DashboardSummary> execute() async {
    final accounts = await _accountRepository.getAccounts();
    final creditCards = await _creditCardRepository.getCreditCards();
    final accountBalances = await Future.wait(
      accounts.map((account) => _calculateAccountBalance.execute(account.id)),
    );
    final creditCardBalances = await Future.wait(
      creditCards.map(
        (creditCard) => _calculateCreditCardBalance.execute(creditCard.id),
      ),
    );
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(),
    );

    final totalAccountBalances = accountBalances.fold(
      0.0,
      (total, balance) => total + balance.currentBalance,
    );
    final totalCreditCardDebt = creditCardBalances.fold(
      0.0,
      (total, balance) => total + balance.currentDebt,
    );
    final currentMonth = _clock();
    final monthStart = DateTime(currentMonth.year, currentMonth.month);
    final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    var monthlyIncome = 0.0;
    var monthlyExpense = 0.0;
    var transactionCount = 0;

    for (final transaction in transactions) {
      if (transaction.isDeleted ||
          transaction.transactionDate.isBefore(monthStart) ||
          !transaction.transactionDate.isBefore(nextMonth)) {
        continue;
      }

      transactionCount++;
      switch (transaction.transactionType) {
        case TransactionType.income when transaction.accountId != null:
          monthlyIncome += transaction.amount.abs();
        case TransactionType.expense:
          monthlyExpense += transaction.amount.abs();
        case TransactionType.income:
        case TransactionType.transfer:
          continue;
      }
    }

    final totalAssets = totalAccountBalances;
    return DashboardSummary(
      totalAccountBalances: totalAccountBalances,
      totalCreditCardDebt: totalCreditCardDebt,
      totalAssets: totalAssets,
      netWorth: totalAccountBalances - totalCreditCardDebt,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      monthlyCashFlow: monthlyIncome - monthlyExpense,
      transactionCount: transactionCount,
    );
  }
}
