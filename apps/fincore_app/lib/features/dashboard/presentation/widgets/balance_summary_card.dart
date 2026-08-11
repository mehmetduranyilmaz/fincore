import 'package:fincore_app/core/theme/app_colors.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_radius.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/dashboard/presentation/constants/dashboard_strings.dart';
import 'package:flutter/material.dart';

final class BalanceSummaryCard extends StatelessWidget {
  const BalanceSummaryCard({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final successColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.successDark
        : AppColors.success;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FeaturedMetric(
            label: DashboardStrings.netWorth,
            value: AppFormatters.currency(summary.netWorth),
            color: summary.netWorth >= 0
                ? successColor
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _SummaryMetric(
                label: DashboardStrings.totalAccountBalances,
                value: AppFormatters.currency(summary.totalAccountBalances),
                color: successColor,
              ),
              _SummaryMetric(
                label: DashboardStrings.totalCreditCardDebt,
                value: AppFormatters.currency(summary.totalCreditCardDebt),
                color: Theme.of(context).colorScheme.error,
              ),
              _SummaryMetric(
                label: DashboardStrings.monthlyIncome,
                value: AppFormatters.currency(summary.monthlyIncome),
                color: successColor,
              ),
              _SummaryMetric(
                label: DashboardStrings.monthlyExpense,
                value: AppFormatters.currency(summary.monthlyExpense),
                color: Theme.of(context).colorScheme.error,
              ),
              _SummaryMetric(
                label: DashboardStrings.monthlyCashFlow,
                value: AppFormatters.currency(summary.monthlyCashFlow),
                color: summary.monthlyCashFlow >= 0
                    ? successColor
                    : Theme.of(context).colorScheme.error,
              ),
              _SummaryMetric(
                label: DashboardStrings.transactionCount,
                value: summary.transactionCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _FeaturedMetric extends StatelessWidget {
  const _FeaturedMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
        ),
        borderRadius: AppRadius.lgBorderRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: AppRadius.mdBorderRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 220,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: AppRadius.mdBorderRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
