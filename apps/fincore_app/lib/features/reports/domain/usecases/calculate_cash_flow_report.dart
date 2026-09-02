import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/reports/domain/entities/cash_flow_report.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class CalculateCashFlowReportUseCase {
  const CalculateCashFlowReportUseCase(
    this._transactionRepository,
    this._accountRepository,
  );

  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;

  Future<CashFlowReport> execute({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final accounts = await _accountRepository.getAccounts();
    final accountById = {for (final account in accounts) account.id: account};
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(endDate: endDate),
    );
    final balances = {
      for (final account in accounts) account.id: account.openingBalance,
    };
    final inflows = <CashFlowEntry>[];
    final outflows = <CashFlowEntry>[];

    final chronological = transactions.where((item) => !item.isDeleted).toList()
      ..sort(
        (left, right) => left.transactionDate.compareTo(right.transactionDate),
      );
    for (final transaction in chronological) {
      final accountId = transaction.accountId;
      final account = accountId == null ? null : accountById[accountId];
      if (account == null) continue;
      final delta = switch (transaction.transactionType) {
        TransactionType.income => transaction.amount.abs(),
        TransactionType.expense => -transaction.amount.abs(),
        TransactionType.transfer => transaction.amount,
      };
      balances.update(account.id, (value) => value + delta);
      if (transaction.transactionDate.isBefore(startDate) ||
          transaction.transferGroupId != null) {
        continue;
      }
      final entry = CashFlowEntry(
        transactionId: transaction.id,
        description: transaction.merchant,
        accountName: account.name,
        currencyCode: account.currencyCode,
        amount: delta.abs(),
        isInflow: delta >= 0,
      );
      (entry.isInflow ? inflows : outflows).add(entry);
    }

    return CashFlowReport(
      inflows: inflows.reversed.toList(),
      outflows: outflows.reversed.toList(),
      accountBalances: [
        for (final account in accounts)
          CashFlowAccountBalance(
            accountName: account.name,
            currencyCode: account.currencyCode,
            balance: balances[account.id]!,
            isCash: account.type == AccountType.cash,
          ),
      ],
    );
  }
}
