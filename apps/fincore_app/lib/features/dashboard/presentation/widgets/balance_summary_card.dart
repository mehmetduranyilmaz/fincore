import 'package:fincore_app/core/theme/app_colors.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/dashboard/presentation/constants/dashboard_strings.dart';
import 'package:fincore_app/features/dashboard/presentation/utils/dashboard_formatters.dart';
import 'package:flutter/material.dart';

final class BalanceSummaryCard extends StatelessWidget {
  const BalanceSummaryCard({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        children: [
          _SummaryMetric(
            label: DashboardStrings.totalBalance,
            value: DashboardFormatters.currency(summary.totalBalance),
            color: AppColors.success,
          ),
          _SummaryMetric(
            label: DashboardStrings.monthlyExpense,
            value: DashboardFormatters.currency(summary.monthlyExpense),
          ),
          _SummaryMetric(
            label: DashboardStrings.creditCardDebt,
            value: DashboardFormatters.currency(summary.creditCardDebt),
            color: Theme.of(context).colorScheme.error,
          ),
        ],
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
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
