import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/presentation/constants/category_strings.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_icon.dart';
import 'package:flutter/material.dart';

final class CategorySelector extends StatelessWidget {
  const CategorySelector({
    required this.categories,
    required this.type,
    required this.value,
    required this.onChanged,
    super.key,
  });

  static const String _none = '__none__';

  final List<Category> categories;
  final CategoryType type;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = categories
        .where((category) => category.type == type)
        .toList(growable: false);
    final selectedValue = options.any((category) => category.id == value)
        ? value
        : _none;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: const InputDecoration(labelText: CategoryStrings.category),
      items: [
        const DropdownMenuItem(
          value: _none,
          child: Text(CategoryStrings.noCategory),
        ),
        ...options.map(
          (category) => DropdownMenuItem(
            value: category.id,
            child: Row(
              children: [
                CategoryIcon(
                  icon: category.icon,
                  color: category.color,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(CategoryStrings.displayName(category.name)),
              ],
            ),
          ),
        ),
      ],
      onChanged: (categoryId) {
        onChanged(categoryId == _none ? null : categoryId);
      },
    );
  }
}
