import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_balance.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:fincore_app/features/credit_cards/presentation/widgets/credit_limit_progress.dart';
import 'package:flutter/material.dart';

final class CreditCardBalanceSummary extends StatelessWidget {
  const CreditCardBalanceSummary({
    required this.balance,
    required this.creditLimit,
    required this.currencyCode,
    super.key,
  });

  final CreditCardBalance balance;
  final double creditLimit;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CreditLimitProgress(
          creditLimit: creditLimit,
          currentDebt: balance.currentDebt,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            _CreditCardMetric(
              label: CreditCardStrings.creditLimit,
              value: AppFormatters.currency(
                creditLimit,
                currencyCode: currencyCode,
              ),
            ),
            _CreditCardMetric(
              label: CreditCardStrings.currentDebt,
              value: AppFormatters.currency(
                balance.currentDebt,
                currencyCode: currencyCode,
              ),
            ),
            _CreditCardMetric(
              label: CreditCardStrings.availableLimit,
              value: AppFormatters.currency(
                balance.availableLimit,
                currencyCode: currencyCode,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _CreditCardMetric extends StatelessWidget {
  const _CreditCardMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: textTheme.labelLarge),
        ],
      ),
    );
  }
}
