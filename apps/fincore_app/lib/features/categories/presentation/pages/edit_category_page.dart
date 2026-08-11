import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/categories/domain/usecases/update_category.dart';
import 'package:fincore_app/features/categories/presentation/constants/category_strings.dart';
import 'package:fincore_app/features/categories/presentation/controllers/update_category_controller.dart';
import 'package:fincore_app/features/categories/presentation/providers/category_provider.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class EditCategoryPage extends ConsumerStatefulWidget {
  const EditCategoryPage({required this.categoryId, super.key});

  final String categoryId;

  @override
  ConsumerState<EditCategoryPage> createState() => _EditCategoryPageState();
}

final class _EditCategoryPageState extends ConsumerState<EditCategoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(updateCategoryControllerProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider(widget.categoryId));
    final updateState = ref.watch(updateCategoryControllerProvider);

    ref.listen<UpdateCategoryState>(updateCategoryControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == UpdateCategoryStatus.success && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(CategoryStrings.edit)),
      body: categoryState.when(
        loading: () => const AppLoadingView(),
        error: (_, _) => AppErrorView(
          message: CategoryStrings.unableToLoad,
          onRetry: () => ref.invalidate(categoryProvider(widget.categoryId)),
        ),
        data: (category) {
          if (category == null) {
            return AppErrorView(
              message: CategoryStrings.categoryNotFound,
              onRetry: () =>
                  ref.invalidate(categoryProvider(widget.categoryId)),
            );
          }

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: AppCard(
                    child: CategoryForm(
                      key: ValueKey(category.id),
                      initialValue: CategoryFormValue(
                        name: category.name,
                        icon: category.icon,
                        color: category.color,
                        type: category.type,
                      ),
                      lockType: true,
                      isLoading:
                          updateState.status == UpdateCategoryStatus.loading,
                      errorMessage: updateState.errorMessage,
                      onSubmit: (value) {
                        ref
                            .read(updateCategoryControllerProvider.notifier)
                            .update(
                              UpdateCategoryInput(
                                id: category.id,
                                name: value.name,
                                icon: value.icon,
                                color: value.color,
                              ),
                            );
                      },
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
