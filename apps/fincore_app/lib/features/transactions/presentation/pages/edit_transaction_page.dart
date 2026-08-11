import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/providers/transaction_details_provider.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/edit_transaction_form.dart';
import 'package:fincore_app/features/customers/presentation/widgets/edit_customer_payment_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class EditTransactionPage extends ConsumerWidget {
  const EditTransactionPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(transactionDetailsProvider(transactionId));

    return Scaffold(
      appBar: AppBar(title: const Text(TransactionStrings.edit)),
      body: details.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorView(
          message: ErrorMapper.map(error),
          retryLabel: TransactionStrings.retry,
          onRetry: () =>
              ref.invalidate(transactionDetailsProvider(transactionId)),
        ),
        data: (transaction) {
          if (transaction == null) {
            return const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: TransactionStrings.notFound,
              description: TransactionStrings.notFoundDescription,
            );
          }
          if (!transaction.isEditable && !transaction.isCustomerPayment) {
            return const AppEmptyState(
              icon: Icons.lock_outline,
              title: TransactionStrings.readOnly,
              description: TransactionStrings.readOnlyDescription,
            );
          }
          if (transaction.isCustomerPayment) {
            return EditCustomerPaymentForm(
              key: ValueKey(transaction.id),
              transaction: transaction,
            );
          }
          return EditTransactionForm(
            key: ValueKey(transaction.id),
            transaction: transaction,
          );
        },
      ),
    );
  }
}
