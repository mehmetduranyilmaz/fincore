import 'dart:async';

import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transactions_list.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

final class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(transactionsControllerProvider.notifier).load());
        final accountsStatus = ref.read(accountsControllerProvider).status;
        if (accountsStatus == AccountsStatus.initial ||
            accountsStatus == AccountsStatus.failure) {
          unawaited(ref.read(accountsControllerProvider.notifier).load());
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionsControllerProvider);
    final accounts = ref.watch(
      accountsControllerProvider.select((state) => state.accounts),
    );

    return _TransactionsContent(
      state: state,
      accounts: accounts,
      onRetry: ref.read(transactionsControllerProvider.notifier).load,
    );
  }
}

final class _TransactionsContent extends StatelessWidget {
  const _TransactionsContent({
    required this.state,
    required this.accounts,
    required this.onRetry,
  });

  final TransactionsState state;
  final List<Account> accounts;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: TransactionStrings.title,
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: TransactionStrings.scanReceiptExpense,
                  onPressed: () => context.push(AppRoutes.createReceiptExpense),
                  icon: const Icon(Icons.document_scanner_outlined),
                ),
                IconButton(
                  tooltip: TransactionStrings.createTransfer,
                  onPressed: () => context.push(AppRoutes.createTransfer),
                  icon: const Icon(Icons.swap_horiz),
                ),
                IconButton(
                  tooltip: TransactionStrings.createManualIncome,
                  onPressed: () => context.push(AppRoutes.createManualIncome),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                IconButton(
                  tooltip: TransactionStrings.createManualExpense,
                  onPressed: () => context.push(AppRoutes.createManualExpense),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TransactionFilters(accounts: accounts),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _TransactionsBody(state: state, onRetry: onRetry),
          ),
        ],
      ),
    );
  }
}

final class _TransactionsBody extends StatelessWidget {
  const _TransactionsBody({required this.state, required this.onRetry});

  final TransactionsState state;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      TransactionsStatus.initial ||
      TransactionsStatus.loading => const AppLoadingView(),
      TransactionsStatus.failure => AppErrorView(
        message: state.errorMessage ?? TransactionStrings.unableToLoad,
        retryLabel: TransactionStrings.retry,
        onRetry: onRetry,
      ),
      TransactionsStatus.loaded when state.transactions.isEmpty =>
        const AppEmptyState(
          icon: Icons.receipt_long_outlined,
          title: TransactionStrings.noTransactions,
          description: TransactionStrings.noTransactionsDescription,
        ),
      TransactionsStatus.loaded => TransactionsList(
        transactions: state.transactions,
        onTransactionTap: (transaction) =>
            context.push(AppRoutes.transactionDetailsLocation(transaction.id)),
      ),
    };
  }
}
