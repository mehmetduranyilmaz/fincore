import 'package:fincore_app/features/categories/domain/errors/category_operation_exception.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_usage_repository.dart';

final class DeleteCategory {
  const DeleteCategory(this._repository, this._usageRepository);

  final CategoryRepository _repository;
  final CategoryUsageRepository _usageRepository;

  Future<void> execute(String categoryId) async {
    final category = await _repository.getById(categoryId);
    if (category == null) {
      throw const CategoryOperationException('Kategori bulunamadı.');
    }
    if (await _usageRepository.hasUsage(categoryId)) {
      throw const CategoryOperationException(
        'Hareket görmüş kategori silinemez.',
      );
    }
    await _repository.delete(categoryId);
  }
}
