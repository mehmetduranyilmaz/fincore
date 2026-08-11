import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/errors/category_operation_exception.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fincore_app/features/categories/domain/usecases/category_validator.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';

final class UpdateCategoryInput {
  const UpdateCategoryInput({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final String icon;
  final int color;
}

final class UpdateCategory {
  const UpdateCategory(this._repository);

  final CategoryRepository _repository;

  Future<Category> execute(UpdateCategoryInput input) async {
    final existing = await _repository.getById(input.id);
    if (existing == null) {
      throw StateError('Category not found.');
    }

    final name = CategoryValidator.validateName(input.name);
    final categories = await _repository.getAll();
    if (categories.any(
      (item) =>
          item.id != existing.id &&
          TurkishText.normalize(item.name) == TurkishText.normalize(name),
    )) {
      throw const CategoryOperationException(
        'Aynı isimde başka bir kategori zaten var.',
      );
    }
    final category = Category(
      id: existing.id,
      name: name,
      icon: input.icon,
      color: input.color,
      type: existing.type,
    );

    await _repository.update(category);
    return category;
  }
}
