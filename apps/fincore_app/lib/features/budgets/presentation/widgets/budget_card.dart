import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/features/budgets/presentation/constants/budget_strings.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:fincore_app/features/budgets/presentation/widgets/budget_progress_bar.dart';
import 'package:flutter/material.dart';

final class BudgetCard extends StatelessWidget {
  const BudgetCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.isDeleting = false,
    super.key,
  });

  final BudgetViewData item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final budget = item.budget;
    final progress = item.progress;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.categoryName, style: textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      BudgetStrings.periodLabel(budget.month, budget.year),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: BudgetStrings.edit,
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              if (isDeleting)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  tooltip: BudgetStrings.delete,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _BudgetMetric(
                label: BudgetStrings.monthlyBudget,
                value: AppFormatters.currency(progress.budgetAmount),
              ),
              _BudgetMetric(
                label: BudgetStrings.spent,
                value: AppFormatters.currency(progress.spentAmount),
              ),
              _BudgetMetric(
                label: BudgetStrings.remaining,
                value: AppFormatters.currency(progress.remainingAmount),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          BudgetProgressBar(progress: progress.progress),
        ],
      ),
    );
  }
}

final class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
