import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/dashboard/domain/entities/category_spending.dart';
import 'package:fincore_app/features/dashboard/presentation/constants/dashboard_strings.dart';
import 'package:fincore_app/features/dashboard/presentation/utils/dashboard_formatters.dart';
import 'package:flutter/material.dart';

final class CategorySpendingSection extends StatelessWidget {
  const CategorySpendingSection({required this.categories, super.key});

  final List<CategorySpending> categories;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(title: DashboardStrings.categorySpending),
          const SizedBox(height: AppSpacing.lg),
          if (categories.isEmpty)
            const AppEmptyState(
              icon: Icons.donut_large_outlined,
              title: DashboardStrings.noCategorySpending,
              description: DashboardStrings.noCategorySpendingDescription,
            )
          else
            for (final category in categories) ...[
              _CategorySpendingItem(category: category),
              if (category != categories.last)
                const SizedBox(height: AppSpacing.md),
            ],
        ],
      ),
    );
  }
}

final class _CategorySpendingItem extends StatelessWidget {
  const _CategorySpendingItem({required this.category});

  final CategorySpending category;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(category.category)),
            Text(
              DashboardFormatters.currency(category.amount),
              style: textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(
          value: category.percentage.clamp(0, 1),
          borderRadius: const BorderRadius.all(Radius.circular(4)),
        ),
      ],
    );
  }
}
