import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/features/categories/domain/usecases/create_category.dart';
import 'package:fincore_app/features/categories/presentation/constants/category_strings.dart';
import 'package:fincore_app/features/categories/presentation/controllers/create_category_controller.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreateCategoryPage extends ConsumerStatefulWidget {
  const CreateCategoryPage({super.key});

  @override
  ConsumerState<CreateCategoryPage> createState() => _CreateCategoryPageState();
}

final class _CreateCategoryPageState extends ConsumerState<CreateCategoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(createCategoryControllerProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createCategoryControllerProvider);

    ref.listen<CreateCategoryState>(createCategoryControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == CreateCategoryStatus.success && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(CategoryStrings.create)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AppCard(
                child: CategoryForm(
                  isLoading: state.status == CreateCategoryStatus.loading,
                  errorMessage: state.errorMessage,
                  onSubmit: (value) {
                    ref
                        .read(createCategoryControllerProvider.notifier)
                        .create(
                          CreateCategoryInput(
                            name: value.name,
                            icon: value.icon,
                            color: value.color,
                            type: value.type,
                          ),
                        );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
