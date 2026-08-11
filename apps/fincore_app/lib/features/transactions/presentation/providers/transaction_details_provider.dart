import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionDetailsProvider = FutureProvider.family<Transaction?, String>((
  ref,
  transactionId,
) {
  return ref.watch(getTransactionDetailsProvider).execute(transactionId);
});
