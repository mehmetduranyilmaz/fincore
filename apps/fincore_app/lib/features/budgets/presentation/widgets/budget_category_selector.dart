import 'package:fincore_app/features/budgets/presentation/constants/budget_strings.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/presentation/constants/category_strings.dart';
import 'package:flutter/material.dart';

final class BudgetCategorySelector extends StatelessWidget {
  const BudgetCategorySelector({
    required this.categories,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<Category> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = categories.any((category) => category.id == value)
        ? value
        : null;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      decoration: const InputDecoration(labelText: BudgetStrings.category),
      hint: const Text(BudgetStrings.selectCategory),
      items: [
        for (final category in categories)
          DropdownMenuItem(
            value: category.id,
            child: Text(CategoryStrings.displayName(category.name)),
          ),
      ],
      onChanged: onChanged,
      validator: (selection) =>
          selection == null ? BudgetStrings.requiredField : null,
    );
  }
}
