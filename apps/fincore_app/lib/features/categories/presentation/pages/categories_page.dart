import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/presentation/constants/category_strings.dart';
import 'package:fincore_app/features/categories/presentation/controllers/categories_controller.dart';
import 'package:fincore_app/features/categories/presentation/controllers/delete_category_controller.dart';
import 'package:fincore_app/features/categories/presentation/widgets/categories_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

final class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(categoriesControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesControllerProvider);
    final deleteState = ref.watch(deleteCategoryControllerProvider);

    ref.listen<DeleteCategoryState>(deleteCategoryControllerProvider, (
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
      CategoriesStatus.initial ||
      CategoriesStatus.loading => const AppLoadingView(),
      CategoriesStatus.failure => AppErrorView(
        message: state.errorMessage ?? CategoryStrings.unableToLoad,
        retryLabel: CategoryStrings.retry,
        onRetry: ref.read(categoriesControllerProvider.notifier).load,
      ),
      CategoriesStatus.loaded => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: CategoryStrings.title,
              action: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.createCategory),
                icon: const Icon(Icons.add),
                label: const Text(CategoryStrings.create),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: state.categories.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.category_outlined,
                      title: CategoryStrings.noCategories,
                      description: CategoryStrings.noCategoriesDescription,
                    )
                  : CategoriesList(
                      categories: state.categories,
                      deletingCategoryId:
                          deleteState.status == DeleteCategoryStatus.loading
                          ? deleteState.categoryId
                          : null,
                      onEdit: (category) => context.push(
                        AppRoutes.editCategoryLocation(category.id),
                      ),
                      onDelete: _confirmDelete,
                    ),
            ),
          ],
        ),
      ),
    };
  }

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(CategoryStrings.deleteTitle),
        content: const Text(CategoryStrings.deleteMessage),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text(CategoryStrings.cancel),
          ),
          FilledButton(
            onPressed: () => context.pop(true),
            child: const Text(CategoryStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(deleteCategoryControllerProvider.notifier)
          .delete(category.id);
    }
  }
}
