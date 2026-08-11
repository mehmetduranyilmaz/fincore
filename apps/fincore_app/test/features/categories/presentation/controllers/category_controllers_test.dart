import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/categories/data/datasources/category_mock_data_source.dart';
import 'package:fincore_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_usage_repository.dart';
import 'package:fincore_app/features/categories/domain/usecases/create_category.dart';
import 'package:fincore_app/features/categories/domain/usecases/delete_category.dart';
import 'package:fincore_app/features/categories/domain/usecases/update_category.dart';
import 'package:fincore_app/features/categories/presentation/controllers/categories_controller.dart';
import 'package:fincore_app/features/categories/presentation/controllers/create_category_controller.dart';
import 'package:fincore_app/features/categories/presentation/controllers/delete_category_controller.dart';
import 'package:fincore_app/features/categories/presentation/controllers/update_category_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'list, create, update and delete controllers keep state in sync',
    () async {
      final repository = CategoryRepositoryImpl(
        CategoryMockDataSource(seed: const []),
      );
      final container = ProviderContainer(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(repository),
          createCategoryProvider.overrideWithValue(
            CreateCategory(repository, idGenerator: () => 'category-test'),
          ),
          deleteCategoryProvider.overrideWithValue(
            DeleteCategory(repository, const _UnusedCategoryRepository()),
          ),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(appShellNavigationControllerProvider.notifier)
          .select(AppShellDestination.categories);

      await container.read(categoriesControllerProvider.notifier).load();
      expect(
        container.read(categoriesControllerProvider).status,
        CategoriesStatus.loaded,
      );

      await container
          .read(createCategoryControllerProvider.notifier)
          .create(
            const CreateCategoryInput(
              name: 'Salary',
              icon: 'payments',
              color: 0xFF1565C0,
              type: CategoryType.income,
            ),
          );
      expect(
        container.read(createCategoryControllerProvider).status,
        CreateCategoryStatus.success,
      );
      expect(
        container.read(categoriesControllerProvider).categories,
        hasLength(1),
      );

      await container
          .read(updateCategoryControllerProvider.notifier)
          .update(
            const UpdateCategoryInput(
              id: 'category-test',
              name: 'Monthly Salary',
              icon: 'trending_up',
              color: 0xFF2E7D32,
            ),
          );
      expect(
        container.read(updateCategoryControllerProvider).status,
        UpdateCategoryStatus.success,
      );
      expect(
        container.read(categoriesControllerProvider).categories.single.name,
        'Monthly Salary',
      );

      await container
          .read(deleteCategoryControllerProvider.notifier)
          .delete('category-test');
      expect(
        container.read(deleteCategoryControllerProvider).status,
        DeleteCategoryStatus.success,
      );
      expect(container.read(categoriesControllerProvider).categories, isEmpty);
    },
  );
}

final class _UnusedCategoryRepository implements CategoryUsageRepository {
  const _UnusedCategoryRepository();

  @override
  Future<bool> hasUsage(String categoryId) async => false;
}
