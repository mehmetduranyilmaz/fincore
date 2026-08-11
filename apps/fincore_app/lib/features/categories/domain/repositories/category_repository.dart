import 'package:fincore_app/features/categories/domain/entities/category.dart';

abstract interface class CategoryRepository {
  Future<List<Category>> getAll();

  Future<Category?> getById(String categoryId);

  Future<void> create(Category category);

  Future<void> update(Category category);

  Future<void> delete(String categoryId);
}
