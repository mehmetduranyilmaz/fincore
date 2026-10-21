import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionDetailsProvider = FutureProvider.family<Transaction?, String>((
  ref,
  transactionId,
) {
  return ref.watch(getTransactionDetailsProvider).execute(transactionId);
});

/// Display name of the account or credit card a transaction belongs to,
/// resolved from the saved records. Null when the source no longer exists.
final transactionSourceNameProvider = FutureProvider.family<String?, String>((
  ref,
  transactionId,
) async {
  final transaction = await ref.watch(
    transactionDetailsProvider(transactionId).future,
  );
  if (transaction == null) return null;
  if (transaction.creditCardId case final creditCardId?) {
    final cards = await ref
        .watch(creditCardRepositoryProvider)
        .getCreditCards();
    final card = cards.where((item) => item.id == creditCardId).firstOrNull;
    return card == null
        ? null
        : '${card.bankName} ${card.cardName} • ****${card.lastFourDigits}';
  }
  if (transaction.accountId case final accountId?) {
    final accounts = await ref.watch(accountRepositoryProvider).getAccounts();
    return accounts.where((item) => item.id == accountId).firstOrNull?.name;
  }
  return null;
});
