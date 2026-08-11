import 'package:fincore_app/features/categories/data/datasources/category_mock_data_source.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';

final class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._dataSource);

  final CategoryDataSource _dataSource;

  @override
  Future<List<Category>> getAll() async {
    return List.unmodifiable(await _dataSource.getAll());
  }

  @override
  Future<Category?> getById(String categoryId) {
    return _dataSource.getById(categoryId);
  }

  @override
  Future<void> create(Category category) {
    return _dataSource.insert(category);
  }

  @override
  Future<void> update(Category category) {
    return _dataSource.replace(category);
  }

  @override
  Future<void> delete(String categoryId) {
    return _dataSource.remove(categoryId);
  }
}
