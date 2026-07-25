import 'package:fincore_app/core/theme/app_colors.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/dashboard/domain/entities/recent_transaction.dart';
import 'package:fincore_app/features/dashboard/presentation/constants/dashboard_strings.dart';
import 'package:fincore_app/features/dashboard/presentation/utils/dashboard_formatters.dart';
import 'package:flutter/material.dart';

final class RecentTransactionsSection extends StatelessWidget {
  const RecentTransactionsSection({required this.transactions, super.key});

  final List<RecentTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: DashboardStrings.recentTransactions),
          const SizedBox(height: AppSpacing.md),
          if (transactions.isEmpty)
            const AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: DashboardStrings.noRecentTransactions,
              description: DashboardStrings.noRecentTransactionsDescription,
            )
          else
            for (final (index, transaction) in transactions.indexed) ...[
              _TransactionTile(transaction: transaction),
              if (index < transactions.length - 1) const Divider(),
            ],
        ],
      ),
    );
  }
}

final class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final RecentTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final prefix = isIncome ? '+' : '-';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isIncome ? Icons.south_west : Icons.north_east,
        color: isIncome
            ? AppColors.success
            : Theme.of(context).colorScheme.error,
      ),
      title: Text(transaction.description),
      subtitle: Text(DashboardFormatters.date(transaction.occurredAt)),
      trailing: Text(
        '$prefix${DashboardFormatters.currency(transaction.amount)}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isIncome
              ? AppColors.success
              : Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
