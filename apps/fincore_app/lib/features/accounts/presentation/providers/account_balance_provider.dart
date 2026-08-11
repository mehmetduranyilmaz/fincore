import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_balance.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountBalanceProvider = FutureProvider.family<AccountBalance, String>((
  ref,
  accountId,
) {
  return ref.watch(calculateAccountBalanceProvider).execute(accountId);
});

final accountProvider = FutureProvider.family((ref, String accountId) {
  return ref.watch(accountCommandRepositoryProvider).getById(accountId);
});

final accountHasMovementsProvider = FutureProvider.family<bool, String>((
  ref,
  accountId,
) async {
  final transactions = await ref
      .watch(transactionRepositoryProvider)
      .getTransactions(TransactionFilter(accountId: accountId));
  return transactions.isNotEmpty;
});
