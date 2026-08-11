import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/presentation/constants/category_strings.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_icon.dart';
import 'package:flutter/material.dart';

final class CategoryFormValue {
  const CategoryFormValue({
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

final class CategoryForm extends StatefulWidget {
  const CategoryForm({
    required this.onSubmit,
    required this.isLoading,
    this.initialValue,
    this.errorMessage,
    this.lockType = false,
    super.key,
  });

  final CategoryFormValue? initialValue;
  final ValueChanged<CategoryFormValue> onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final bool lockType;

  @override
  State<CategoryForm> createState() => _CategoryFormState();
}

final class _CategoryFormState extends State<CategoryForm> {
  static const List<int> _colors = [
    0xFF1565C0,
    0xFF2E7D32,
    0xFF6A1B9A,
    0xFFAD1457,
    0xFFEF6C00,
    0xFF455A64,
  ];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _icon;
  late int _color;
  late CategoryType _type;

  @override
  void initState() {
    super.initState();
    final initialValue = widget.initialValue;
    _nameController = TextEditingController(text: initialValue?.name);
    _icon = initialValue?.icon ?? CategoryIcons.values.keys.first;
    _color = initialValue?.color ?? _colors.first;
    _type = initialValue?.type ?? CategoryType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _nameController,
            label: CategoryStrings.name,
            textInputAction: TextInputAction.done,
            validator: (value) => value == null || value.trim().isEmpty
                ? CategoryStrings.requiredField
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _icon,
            decoration: const InputDecoration(labelText: CategoryStrings.icon),
            items: CategoryIcons.values.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Row(
                      children: [
                        Icon(entry.value),
                        const SizedBox(width: AppSpacing.sm),
                        Text(CategoryStrings.iconName(entry.key)),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setState(() => _icon = value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<int>(
            initialValue: _color,
            decoration: const InputDecoration(labelText: CategoryStrings.color),
            items: _colors
                .map(
                  (color) => DropdownMenuItem(
                    value: color,
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: Color(color)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '#${color.toRadixString(16).substring(2).toUpperCase()}',
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setState(() => _color = value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<CategoryType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: CategoryStrings.type),
            items: const [
              DropdownMenuItem(
                value: CategoryType.income,
                child: Text(CategoryStrings.income),
              ),
              DropdownMenuItem(
                value: CategoryType.expense,
                child: Text(CategoryStrings.expense),
              ),
            ],
            onChanged: widget.lockType
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
          ),
          if (widget.errorMessage case final message?) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: CategoryStrings.save,
            isLoading: widget.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    widget.onSubmit(
      CategoryFormValue(
        name: _nameController.text.trim(),
        icon: _icon,
        color: _color,
        type: _type,
      ),
    );
  }
}
