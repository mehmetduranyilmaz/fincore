import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:fincore_app/features/budgets/presentation/widgets/budget_card.dart';
import 'package:flutter/material.dart';

final class BudgetsList extends StatelessWidget {
  const BudgetsList({
    required this.items,
    required this.onEdit,
    required this.onDelete,
    this.deletingBudgetId,
    super.key,
  });

  static const double _gridBreakpoint = 720;

  final List<BudgetViewData> items;
  final ValueChanged<BudgetViewData> onEdit;
  final ValueChanged<BudgetViewData> onDelete;
  final String? deletingBudgetId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _gridBreakpoint) {
          return ListView.separated(
            key: const Key('budgets_list_layout'),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => _card(items[index]),
          );
        }

        return GridView.builder(
          key: const Key('budgets_grid_layout'),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 520,
            mainAxisExtent: 340,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => _card(items[index]),
        );
      },
    );
  }

  Widget _card(BudgetViewData item) {
    return BudgetCard(
      item: item,
      isDeleting: deletingBudgetId == item.budget.id,
      onEdit: () => onEdit(item),
      onDelete: () => onDelete(item),
    );
  }
}
