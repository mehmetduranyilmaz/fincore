import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/budgets/presentation/constants/budget_strings.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/delete_budget_controller.dart';
import 'package:fincore_app/features/budgets/presentation/widgets/budgets_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class BudgetsPage extends ConsumerStatefulWidget {
  const BudgetsPage({super.key});

  @override
  ConsumerState<BudgetsPage> createState() => _BudgetsPageState();
}

final class _BudgetsPageState extends ConsumerState<BudgetsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(budgetsControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetsControllerProvider);
    final deleteState = ref.watch(deleteBudgetControllerProvider);

    ref.listen<DeleteBudgetState>(deleteBudgetControllerProvider, (
      previous,
      next,
    ) {
      final message = next.errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return switch (state.status) {
      BudgetsStatus.initial || BudgetsStatus.loading => const AppLoadingView(),
      BudgetsStatus.failure => AppErrorView(
        message: state.errorMessage ?? BudgetStrings.unableToLoad,
        retryLabel: BudgetStrings.retry,
        onRetry: ref.read(budgetsControllerProvider.notifier).load,
      ),
      BudgetsStatus.loaded => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: BudgetStrings.title,
              action: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.createBudget),
                icon: const Icon(Icons.add),
                label: const Text(BudgetStrings.create),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: state.items.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.savings_outlined,
                      title: BudgetStrings.noBudgets,
                      description: BudgetStrings.noBudgetsDescription,
                    )
                  : BudgetsList(
                      items: state.items,
                      deletingBudgetId:
                          deleteState.status == DeleteBudgetStatus.loading
                          ? deleteState.budgetId
                          : null,
                      onEdit: (item) => context.push(
                        AppRoutes.editBudgetLocation(item.budget.id),
                      ),
                      onDelete: _confirmDelete,
                    ),
            ),
          ],
        ),
      ),
    };
  }

  Future<void> _confirmDelete(BudgetViewData item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(BudgetStrings.deleteTitle),
        content: const Text(BudgetStrings.deleteMessage),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(BudgetStrings.cancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text(BudgetStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(deleteBudgetControllerProvider.notifier)
          .delete(item.budget.id);
    }
  }
}
