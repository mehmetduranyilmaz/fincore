import 'package:fincore_app/core/theme/app_colors.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_balance.dart';
import 'package:fincore_app/features/accounts/presentation/constants/account_strings.dart';
import 'package:fincore_app/features/accounts/presentation/widgets/account_balance_chip.dart';
import 'package:flutter/material.dart';

final class AccountBalanceSummary extends StatelessWidget {
  const AccountBalanceSummary({
    required this.balance,
    required this.currencyCode,
    super.key,
  });

  final AccountBalance balance;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final successColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.successDark
        : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(AccountStrings.currentBalance, style: textTheme.labelMedium),
        AccountBalanceChip(
          balance: balance.currentBalance,
          currencyCode: currencyCode,
        ),
        const SizedBox(height: AppSpacing.xs),
        _BalanceMetric(
          label: AccountStrings.totalIncome,
          amount: balance.totalIncome,
          currencyCode: currencyCode,
          color: successColor,
        ),
        const SizedBox(height: AppSpacing.xs),
        _BalanceMetric(
          label: AccountStrings.totalExpense,
          amount: balance.totalExpense,
          currencyCode: currencyCode,
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }
}

final class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.label,
    required this.amount,
    required this.currencyCode,
    required this.color,
  });

  final String label;
  final double amount;
  final String currencyCode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: ${AppFormatters.currency(amount, currencyCode: currencyCode)}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
      textAlign: TextAlign.end,
    );
  }
}
