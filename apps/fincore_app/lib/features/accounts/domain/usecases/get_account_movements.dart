import 'package:fincore_app/features/accounts/domain/entities/account_movement.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class GetAccountMovementsUseCase {
  const GetAccountMovementsUseCase(
    this._transactionRepository,
    this._accountRepository,
  );

  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;

  Future<List<AccountMovement>> execute({
    required String accountId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final accounts = await _accountRepository.getAccounts();
    final account = accounts.where((item) => item.id == accountId).firstOrNull;
    if (account == null) throw StateError('Account not found.');
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(accountId: accountId, endDate: endDate),
    );
    final chronological =
        transactions
            .where((item) => !item.isDeleted && item.accountId == accountId)
            .toList()
          ..sort((left, right) {
            final date = left.transactionDate.compareTo(right.transactionDate);
            return date != 0 ? date : left.id.compareTo(right.id);
          });

    var balance = account.openingBalance;
    final result = <AccountMovement>[];
    for (final transaction in chronological) {
      balance += switch (transaction.transactionType) {
        TransactionType.income => transaction.amount.abs(),
        TransactionType.expense => -transaction.amount.abs(),
        TransactionType.transfer => transaction.amount,
      };
      if (balance.abs() < 0.000001) balance = 0;
      if (!transaction.transactionDate.isBefore(startDate)) {
        result.add(
          AccountMovement(
            transaction: transaction,
            balanceAfterMovement: balance,
          ),
        );
      }
    }
    return List.unmodifiable(result.reversed);
  }
}
