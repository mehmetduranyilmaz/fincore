import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/delete_transaction_controller.dart';
import 'package:fincore_app/features/transactions/presentation/providers/transaction_details_provider.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_details_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class TransactionDetailsPage extends ConsumerWidget {
  const TransactionDetailsPage({required this.transactionId, super.key});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(transactionDetailsProvider(transactionId));
    final deleteState = ref.watch(deleteTransactionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(TransactionStrings.details),
        actions: [
          if (details.value case final Transaction transaction
              when transaction.canConvertToInstallments)
            IconButton(
              tooltip: TransactionStrings.convertToInstallments,
              onPressed: () => context.push(
                AppRoutes.convertTransactionInstallmentsLocation(transactionId),
              ),
              icon: const Icon(Icons.calendar_month_outlined),
            ),
          if (details.value case final Transaction transaction
              when transaction.isEditable || transaction.isCustomerPayment)
            IconButton(
              tooltip: TransactionStrings.edit,
              onPressed: () => context.push(
                AppRoutes.editTransactionLocation(transactionId),
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (details.value case final Transaction transaction
              when transaction.isDeletable)
            deleteState.status == DeleteTransactionStatus.loading
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: TransactionStrings.delete,
                    onPressed: () => _confirmDelete(context, ref, transaction),
                    icon: const Icon(Icons.delete_outline),
                  ),
        ],
      ),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: TransactionDetailsView(transaction: transaction),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Transaction transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(TransactionStrings.deleteTitle),
        content: const Text(TransactionStrings.deleteMessage),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(TransactionStrings.cancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text(TransactionStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final deleted = await ref
        .read(deleteTransactionControllerProvider.notifier)
        .delete(transaction.id);
    if (deleted && context.mounted) {
      context.pop();
      return;
    }
    if (context.mounted) {
      final message = ref
          .read(deleteTransactionControllerProvider)
          .errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}
