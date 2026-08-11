import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/budgets/domain/usecases/create_budget.dart';
import 'package:fincore_app/features/budgets/presentation/constants/budget_strings.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/create_budget_controller.dart';
import 'package:fincore_app/features/budgets/presentation/providers/budget_categories_provider.dart';
import 'package:fincore_app/features/budgets/presentation/widgets/budget_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreateBudgetPage extends ConsumerStatefulWidget {
  const CreateBudgetPage({super.key});

  @override
  ConsumerState<CreateBudgetPage> createState() => _CreateBudgetPageState();
}

final class _CreateBudgetPageState extends ConsumerState<CreateBudgetPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(createBudgetControllerProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createBudgetControllerProvider);
    final categories = ref.watch(expenseBudgetCategoriesProvider);

    ref.listen<CreateBudgetState>(createBudgetControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == CreateBudgetStatus.success && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(BudgetStrings.create)),
      body: categories.when(
        loading: () => const AppLoadingView(),
        error: (_, _) => AppErrorView(
          message: BudgetStrings.noExpenseCategories,
          onRetry: () => ref.invalidate(expenseBudgetCategoriesProvider),
        ),
        data: (values) {
          if (values.isEmpty) {
            return const AppEmptyState(
              icon: Icons.category_outlined,
              title: BudgetStrings.noExpenseCategories,
              description: BudgetStrings.selectCategory,
            );
          }
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: AppCard(
                    child: BudgetForm(
                      categories: values,
                      isLoading: state.status == CreateBudgetStatus.loading,
                      errorMessage: state.errorMessage,
                      onCancel: () => context.pop(),
                      onSubmit: (value) => ref
                          .read(createBudgetControllerProvider.notifier)
                          .create(
                            CreateBudgetInput(
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
        },
      ),
    );
  }
}
