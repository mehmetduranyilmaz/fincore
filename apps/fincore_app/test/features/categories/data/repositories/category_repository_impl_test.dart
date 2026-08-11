import 'package:fincore_app/features/categories/data/datasources/category_mock_data_source.dart';
import 'package:fincore_app/features/categories/data/repositories/category_repository_impl.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supports deterministic in-memory CRUD operations', () async {
    final repository = CategoryRepositoryImpl(
      CategoryMockDataSource(seed: const []),
    );
    const category = Category(
      id: 'category-test',
      name: 'Test',
      icon: 'payments',
      color: 0xFF1565C0,
      type: CategoryType.income,
    );

    await repository.create(category);
    expect(await repository.getAll(), const [category]);
    expect(await repository.getById(category.id), category);

    const updated = Category(
      id: 'category-test',
      name: 'Updated',
      icon: 'trending_up',
      color: 0xFF2E7D32,
      type: CategoryType.income,
    );
    await repository.update(updated);
    expect(await repository.getById(category.id), updated);

    await repository.delete(category.id);
    expect(await repository.getAll(), isEmpty);
    expect(await repository.getById(category.id), isNull);
  });

  test('prevents category type changes', () async {
    final repository = CategoryRepositoryImpl(
      CategoryMockDataSource(
        seed: const [
          Category(
            id: 'category-test',
            name: 'Test',
            icon: 'payments',
            color: 0xFF1565C0,
            type: CategoryType.income,
          ),
        ],
      ),
    );

    expect(
      () => repository.update(
        const Category(
          id: 'category-test',
          name: 'Test',
          icon: 'payments',
          color: 0xFF1565C0,
          type: CategoryType.expense,
        ),
      ),
      throwsStateError,
    );
  });
}
