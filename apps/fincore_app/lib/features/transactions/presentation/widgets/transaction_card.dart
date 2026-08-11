import 'package:fincore_app/core/theme/app_colors.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart' as design_system;
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:flutter/material.dart';

final class TransactionCard extends StatelessWidget {
  const TransactionCard({required this.transaction, this.onTap, super.key});

  final Transaction transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return design_system.AppCard(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = _TransactionDetails(transaction: transaction);
          final amount = _TransactionAmount(transaction: transaction);

          if (constraints.maxWidth < 420) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: AppSpacing.md),
                amount,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: AppSpacing.md),
              amount,
            ],
          );
        },
      ),
    );
  }
}

final class _TransactionDetails extends StatelessWidget {
  const _TransactionDetails({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final type = TransactionStrings.transactionType(
      transaction.transactionType,
    );
    final source = TransactionStrings.transactionSource(transaction.source);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(transaction.merchant, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(AppFormatters.date(transaction.transactionDate)),
        const SizedBox(height: AppSpacing.xs),
        Text('$type • $source', style: textTheme.bodyMedium),
        if (transaction.isInstallment) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${TransactionStrings.installmentNumber} '
            '${TransactionStrings.installmentLabel(transaction.installmentNumber!, transaction.installmentCount!)}',
            style: textTheme.labelMedium,
          ),
        ],
      ],
    );
  }
}

final class _TransactionAmount extends StatelessWidget {
  const _TransactionAmount({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.transactionType == TransactionType.income;
    final isExpense = transaction.transactionType == TransactionType.expense;
    final successColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.successDark
        : AppColors.success;
    final displayAmount = isExpense
        ? -transaction.amount.abs()
        : transaction.amount;
    final color = isIncome
        ? successColor
        : isExpense
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Text(
      AppFormatters.currency(displayAmount, showPositiveSign: isIncome),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
