import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';

final class GetCategory {
  const GetCategory(this._repository);

  final CategoryRepository _repository;

  Future<Category?> execute(String categoryId) {
    return _repository.getById(categoryId);
  }
}
