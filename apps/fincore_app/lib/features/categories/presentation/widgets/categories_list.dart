import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_card.dart';
import 'package:flutter/material.dart';

final class CategoriesList extends StatelessWidget {
  const CategoriesList({
    required this.categories,
    required this.onEdit,
    required this.onDelete,
    this.deletingCategoryId,
    super.key,
  });

  final List<Category> categories;
  final ValueChanged<Category> onEdit;
  final ValueChanged<Category> onDelete;
  final String? deletingCategoryId;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          onEdit: () => onEdit(category),
          onDelete: () => onDelete(category),
          isDeleting: deletingCategoryId == category.id,
        );
      },
    );
  }
}
