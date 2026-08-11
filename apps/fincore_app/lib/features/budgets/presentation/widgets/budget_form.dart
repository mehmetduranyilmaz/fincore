import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/budgets/presentation/constants/budget_strings.dart';
import 'package:fincore_app/features/budgets/presentation/widgets/budget_category_selector.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:flutter/material.dart';

final class BudgetFormValue {
  const BudgetFormValue({
    required this.categoryId,
    required this.month,
    required this.year,
    required this.amount,
  });

  final String categoryId;
  final int month;
  final int year;
  final double amount;
}

final class BudgetForm extends StatefulWidget {
  const BudgetForm({
    required this.categories,
    required this.onSubmit,
    required this.onCancel,
    required this.isLoading,
    this.initialValue,
    this.errorMessage,
    super.key,
  });

  final List<Category> categories;
  final BudgetFormValue? initialValue;
  final ValueChanged<BudgetFormValue> onSubmit;
  final VoidCallback onCancel;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<BudgetForm> createState() => _BudgetFormState();
}

final class _BudgetFormState extends State<BudgetForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late String? _categoryId;
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    final now = DateTime.now();
    _categoryId = initial?.categoryId;
    _month = initial?.month ?? now.month;
    _year = initial?.year ?? now.year;
    _amountController = TextEditingController(
      text: initial == null ? null : AppFormatters.decimal(initial.amount),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = [
      for (var year = currentYear - 1; year <= currentYear + 5; year++) year,
    ];
    if (!years.contains(_year)) {
      years.add(_year);
      years.sort();
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BudgetCategorySelector(
            categories: widget.categories,
            value: _categoryId,
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _amountController,
            label: BudgetStrings.monthlyBudget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [TurkishDecimalInputFormatter()],
            validator: (value) {
              final amount = AppFormatters.tryParseDecimal(value ?? '');
              return amount == null || !amount.isFinite || amount <= 0
                  ? BudgetStrings.invalidAmount
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _month,
                  decoration: const InputDecoration(
                    labelText: BudgetStrings.month,
                  ),
                  items: [
                    for (var month = 1; month <= 12; month++)
                      DropdownMenuItem(
                        value: month,
                        child: Text(BudgetStrings.months[month - 1]),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _month = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _year,
                  decoration: const InputDecoration(
                    labelText: BudgetStrings.year,
                  ),
                  items: [
                    for (final year in years)
                      DropdownMenuItem(value: year, child: Text('$year')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _year = value);
                    }
                  },
                ),
              ),
            ],
          ),
          if (widget.errorMessage case final message?) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isLoading ? null : widget.onCancel,
                  child: const Text(BudgetStrings.cancel),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: BudgetStrings.save,
                  isLoading: widget.isLoading,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final categoryId = _categoryId;
    final amount = AppFormatters.tryParseDecimal(_amountController.text);
    if (categoryId == null || amount == null) {
      return;
    }
    widget.onSubmit(
      BudgetFormValue(
        categoryId: categoryId,
        month: _month,
        year: _year,
        amount: amount,
      ),
    );
  }
}
