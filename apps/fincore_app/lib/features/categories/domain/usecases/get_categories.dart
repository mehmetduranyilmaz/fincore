import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';

final class GetCategories {
  const GetCategories(this._repository);

  final CategoryRepository _repository;

  Future<List<Category>> execute() async {
    final categories = [...await _repository.getAll()]
      ..sort((left, right) => TurkishText.compare(left.name, right.name));
    return List.unmodifiable(categories);
  }
}
