import 'package:fincore_app/core/theme/app_colors.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:flutter/material.dart';

final class AccountBalanceChip extends StatelessWidget {
  const AccountBalanceChip({
    required this.balance,
    required this.currencyCode,
    super.key,
  });

  final double balance;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    final colorScheme = Theme.of(context).colorScheme;
    final successColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.successDark
        : AppColors.success;

    return Chip(
      backgroundColor: isNegative
          ? colorScheme.errorContainer
          : colorScheme.primaryContainer,
      side: BorderSide.none,
      label: Text(
        AppFormatters.currency(balance, currencyCode: currencyCode),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: isNegative ? colorScheme.error : successColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
