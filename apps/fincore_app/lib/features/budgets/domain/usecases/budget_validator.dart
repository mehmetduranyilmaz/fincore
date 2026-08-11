import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';

abstract final class BudgetValidator {
  static void validateAmount(double amount) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(amount, 'amount');
    }
  }

  static void validatePeriod({required int month, required int year}) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month');
    }
    if (year < 1) {
      throw ArgumentError.value(year, 'year');
    }
  }

  static Future<void> validateCategory(
    String categoryId,
    CategoryRepository repository,
  ) async {
    if (categoryId.trim().isEmpty) {
      throw ArgumentError.value(categoryId, 'categoryId');
    }

    final category = await repository.getById(categoryId);
    if (category == null || category.type != CategoryType.expense) {
      throw ArgumentError.value(categoryId, 'categoryId');
    }
  }
}
