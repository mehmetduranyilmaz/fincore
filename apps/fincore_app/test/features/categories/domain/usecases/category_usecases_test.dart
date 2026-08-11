import 'package:fincore_app/features/categories/data/datasources/category_mock_data_source.dart';
import 'package:fincore_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/domain/errors/category_operation_exception.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_usage_repository.dart';
import 'package:fincore_app/features/categories/domain/usecases/create_category.dart';
import 'package:fincore_app/features/categories/domain/usecases/delete_category.dart';
import 'package:fincore_app/features/categories/domain/usecases/get_categories.dart';
import 'package:fincore_app/features/categories/domain/usecases/update_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('create rejects empty names', () {
    final useCase = CreateCategory(
      CategoryRepositoryImpl(CategoryMockDataSource(seed: const [])),
      idGenerator: () => 'category-test',
    );

    expect(
      () => useCase.execute(
        const CreateCategoryInput(
          name: '   ',
          icon: 'payments',
          color: 0xFF1565C0,
          type: CategoryType.income,
        ),
      ),
      throwsFormatException,
    );
  });

  test('update preserves the original category type', () async {
    final repository = CategoryRepositoryImpl(
      CategoryMockDataSource(
        seed: const [
          Category(
            id: 'category-test',
            name: 'Salary',
            icon: 'payments',
            color: 0xFF1565C0,
            type: CategoryType.income,
          ),
        ],
      ),
    );

    final category = await UpdateCategory(repository).execute(
      const UpdateCategoryInput(
        id: 'category-test',
        name: 'Monthly Salary',
        icon: 'trending_up',
        color: 0xFF2E7D32,
      ),
    );

    expect(category.type, CategoryType.income);
    expect(category.name, 'Monthly Salary');
  });

  test('default categories contain the requested utility icons', () {
    final byName = {
      for (final category in CategoryMockDataSource.defaultCategories)
        category.name: category.icon,
    };

    expect(byName['Araç Bakım'], 'car_repair');
    expect(byName['Eğitim'], 'school');
    expect(byName['Elektrik'], 'electric_bolt');
    expect(byName['Doğalgaz'], 'local_fire_department');
    expect(byName['İnternet'], 'wifi');
    expect(byName['Vodafone'], 'phone_android');
    expect(byName['Turkcell'], 'cell_tower');
    expect(byName['Su'], 'water_drop');
  });

  test('categories are sorted using the Turkish alphabet', () async {
    final repository = CategoryRepositoryImpl(
      CategoryMockDataSource(
        seed: const [
          Category(
            id: '3',
            name: 'Züccaciye',
            icon: 'shopping_cart',
            color: 0,
            type: CategoryType.expense,
          ),
          Category(
            id: '1',
            name: 'Çocuk',
            icon: 'child_care',
            color: 0,
            type: CategoryType.expense,
          ),
          Category(
            id: '2',
            name: 'Eğitim',
            icon: 'school',
            color: 0,
            type: CategoryType.expense,
          ),
        ],
      ),
    );

    final categories = await GetCategories(repository).execute();

    expect(categories.map((category) => category.name), [
      'Çocuk',
      'Eğitim',
      'Züccaciye',
    ]);
  });

  test('category names are unique regardless of type and casing', () {
    final repository = CategoryRepositoryImpl(
      CategoryMockDataSource(
        seed: const [
          Category(
            id: 'existing',
            name: 'Eğitim',
            icon: 'school',
            color: 0,
            type: CategoryType.expense,
          ),
        ],
      ),
    );

    expect(
      () => CreateCategory(repository).execute(
        const CreateCategoryInput(
          name: '  EĞİTİM ',
          icon: 'payments',
          color: 0,
          type: CategoryType.income,
        ),
      ),
      throwsA(isA<CategoryOperationException>()),
    );
  });

  test('does not delete a category that has movement history', () async {
    final repository = CategoryRepositoryImpl(
      CategoryMockDataSource(seed: const [_category]),
    );

    await expectLater(
      DeleteCategory(
        repository,
        const _CategoryUsageRepository(true),
      ).execute(_category.id),
      throwsA(isA<CategoryOperationException>()),
    );
    expect(await repository.getById(_category.id), _category);
  });

  test('deletes a category that has never been used', () async {
    final repository = CategoryRepositoryImpl(
      CategoryMockDataSource(seed: const [_category]),
    );

    await DeleteCategory(
      repository,
      const _CategoryUsageRepository(false),
    ).execute(_category.id);

    expect(await repository.getById(_category.id), isNull);
  });
}

const _category = Category(
  id: 'category-unused',
  name: 'Kullanılmayan',
  icon: 'shopping_cart',
  color: 0xFF1565C0,
  type: CategoryType.expense,
);

final class _CategoryUsageRepository implements CategoryUsageRepository {
  const _CategoryUsageRepository(this.hasMovements);

  final bool hasMovements;

  @override
  Future<bool> hasUsage(String categoryId) async => hasMovements;
}
