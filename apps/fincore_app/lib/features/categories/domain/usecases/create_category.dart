import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/domain/errors/category_operation_exception.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fincore_app/features/categories/domain/usecases/category_validator.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';

typedef CategoryIdGenerator = String Function();

final class CreateCategoryInput {
  const CreateCategoryInput({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  final String name;
  final String icon;
  final int color;
  final CategoryType type;
}

final class CreateCategory {
  CreateCategory(this._repository, {CategoryIdGenerator? idGenerator})
    : _idGenerator = idGenerator ?? _generateId;

  final CategoryRepository _repository;
  final CategoryIdGenerator _idGenerator;

  Future<Category> execute(CreateCategoryInput input) async {
    final name = CategoryValidator.validateName(input.name);
    final categories = await _repository.getAll();
    if (categories.any(
      (item) => TurkishText.normalize(item.name) == TurkishText.normalize(name),
    )) {
      throw const CategoryOperationException(
        'Aynı isimde başka bir kategori zaten var.',
      );
    }
    final category = Category(
      id: _idGenerator(),
      name: name,
      icon: input.icon,
      color: input.color,
      type: input.type,
    );

    await _repository.create(category);
    return category;
  }

  static String _generateId() {
    return 'category-${DateTime.now().microsecondsSinceEpoch}';
  }
}
