import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_movement.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerBalanceProvider = FutureProvider.family<double, String>((
  ref,
  customerId,
) {
  return ref.watch(calculateCustomerBalanceProvider).execute(customerId);
});

final customerProvider = FutureProvider.family((ref, String customerId) {
  return ref.watch(customerRepositoryProvider).getById(customerId);
});

final customerHasMovementsProvider = FutureProvider.family<bool, String>((
  ref,
  customerId,
) async {
  final transactions = await ref
      .watch(transactionRepositoryProvider)
      .getTransactions(TransactionFilter());
  return transactions.any((item) => item.customerId == customerId);
});

final customerMovementsProvider =
    FutureProvider.family<List<CustomerMovement>, String>((ref, customerId) {
      return ref.watch(getCustomerMovementsProvider).execute(customerId);
    });
