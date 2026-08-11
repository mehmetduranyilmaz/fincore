import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/budgets/domain/entities/budget.dart';
import 'package:fincore_app/features/budgets/domain/usecases/update_budget.dart';
import 'package:fincore_app/features/budgets/presentation/constants/budget_strings.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/edit_budget_controller.dart';
import 'package:fincore_app/features/budgets/presentation/providers/budget_categories_provider.dart';
import 'package:fincore_app/features/budgets/presentation/widgets/budget_form.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class EditBudgetPage extends ConsumerStatefulWidget {
  const EditBudgetPage({required this.budgetId, super.key});

  final String budgetId;

  @override
  ConsumerState<EditBudgetPage> createState() => _EditBudgetPageState();
}

final class _EditBudgetPageState extends ConsumerState<EditBudgetPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(editBudgetControllerProvider.notifier).reset();
        if (ref.read(budgetsControllerProvider).status ==
            BudgetsStatus.initial) {
          ref.read(budgetsControllerProvider.notifier).load();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetsControllerProvider);
    final categories = ref.watch(expenseBudgetCategoriesProvider);
    final editState = ref.watch(editBudgetControllerProvider);

    ref.listen<EditBudgetState>(editBudgetControllerProvider, (previous, next) {
      if (next.status == EditBudgetStatus.success && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(BudgetStrings.edit)),
      body: _body(budgets, categories, editState),
    );
  }

  Widget _body(
    BudgetsState budgets,
    AsyncValue<List<Category>> categories,
    EditBudgetState editState,
  ) {
    if (budgets.status == BudgetsStatus.initial ||
        budgets.status == BudgetsStatus.loading ||
        categories.isLoading) {
      return const AppLoadingView();
    }
    if (budgets.status == BudgetsStatus.failure || categories.hasError) {
      return AppErrorView(
        message: BudgetStrings.unableToLoad,
        onRetry: () {
          ref.read(budgetsControllerProvider.notifier).load();
          ref.invalidate(expenseBudgetCategoriesProvider);
        },
      );
    }

    Budget? budget;
    for (final item in budgets.items) {
      if (item.budget.id == widget.budgetId) {
        budget = item.budget;
        break;
      }
    }
    final values = categories.value;
    if (budget == null || values == null) {
      return AppErrorView(
        message: BudgetStrings.budgetNotFound,
        onRetry: ref.read(budgetsControllerProvider.notifier).load,
      );
    }
    final selectedBudget = budget;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: AppCard(
              child: BudgetForm(
                key: ValueKey(selectedBudget.id),
                categories: values,
                initialValue: BudgetFormValue(
                  categoryId: selectedBudget.categoryId,
                  month: selectedBudget.month,
                  year: selectedBudget.year,
                  amount: selectedBudget.amount,
                ),
                isLoading: editState.status == EditBudgetStatus.loading,
                errorMessage: editState.errorMessage,
                onCancel: () => context.pop(),
                onSubmit: (value) => ref
                    .read(editBudgetControllerProvider.notifier)
                    .update(
                      UpdateBudgetInput(
                        id: selectedBudget.id,
                        categoryId: value.categoryId,
                        month: value.month,
                        year: value.year,
                        amount: value.amount,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
