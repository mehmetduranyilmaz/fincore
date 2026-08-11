import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/services/transaction_category_validator.dart';

final class CategoryAssignmentValidator
    implements TransactionCategoryValidator {
  const CategoryAssignmentValidator(this._repository);

  final CategoryRepository _repository;

  @override
  Future<void> validate({
    required String categoryId,
    required TransactionType transactionType,
  }) async {
    final category = await _repository.getById(categoryId);
    final expectedType = transactionType == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    if (category == null || category.type != expectedType) {
      throw StateError('Category is not available for this transaction.');
    }
  }
}
