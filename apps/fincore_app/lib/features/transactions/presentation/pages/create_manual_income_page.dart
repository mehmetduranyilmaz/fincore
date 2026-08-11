import 'dart:async';

import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/presentation/controllers/categories_controller.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_selector.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_manual_income_input.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/create_income_controller.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_account_selector.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreateManualIncomePage extends ConsumerStatefulWidget {
  const CreateManualIncomePage({super.key});

  @override
  ConsumerState<CreateManualIncomePage> createState() =>
      _CreateManualIncomePageState();
}

final class _CreateManualIncomePageState
    extends ConsumerState<CreateManualIncomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late DateTime _transactionDate;
  String? _accountId;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _transactionDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(createIncomeControllerProvider.notifier).reset();
        _loadAccounts();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createIncomeControllerProvider);
    final accounts = ref.watch(
      accountsControllerProvider.select((state) => state.accounts),
    );
    final categories = ref.watch(
      categoriesControllerProvider.select((state) => state.categories),
    );

    ref.listen<CreateIncomeState>(createIncomeControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == CreateIncomeStatus.success && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(TransactionStrings.createManualIncome)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TransactionAccountSelector(
                        label: TransactionStrings.account,
                        accounts: accounts,
                        value: _accountId,
                        onChanged: (accountId) {
                          setState(() => _accountId = accountId);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _amountController,
                        label: TransactionStrings.amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: const [TurkishDecimalInputFormatter()],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return TransactionStrings.requiredField;
                          }
                          return _parseAmount(value) == null
                              ? TransactionStrings.invalidAmount
                              : null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _descriptionController,
                        label: TransactionStrings.description,
                        textInputAction: TextInputAction.done,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? TransactionStrings.requiredField
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TransactionDateField(
                        value: _transactionDate,
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CategorySelector(
                        categories: categories,
                        type: CategoryType.income,
                        value: _categoryId,
                        onChanged: (categoryId) {
                          setState(() => _categoryId = categoryId);
                        },
                      ),
                      if (createState.errorMessage case final message?) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: TransactionStrings.saveIncome,
                        isLoading:
                            createState.status == CreateIncomeStatus.loading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _loadAccounts() {
    final status = ref.read(accountsControllerProvider).status;
    if (status == AccountsStatus.initial || status == AccountsStatus.failure) {
      unawaited(ref.read(accountsControllerProvider.notifier).load());
    }

    final categoriesStatus = ref.read(categoriesControllerProvider).status;
    if (categoriesStatus == CategoriesStatus.initial ||
        categoriesStatus == CategoriesStatus.failure) {
      unawaited(ref.read(categoriesControllerProvider.notifier).load());
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (selectedDate != null && mounted) {
      setState(() => _transactionDate = selectedDate);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(createIncomeControllerProvider.notifier)
        .create(
          CreateManualIncomeInput(
            accountId: _accountId!,
            amount: _parseAmount(_amountController.text)!,
            description: _descriptionController.text.trim(),
            categoryId: _categoryId,
            transactionDate: _transactionDate,
          ),
        );
  }

  double? _parseAmount(String value) {
    final amount = AppFormatters.tryParseDecimal(value);
    return amount != null && amount > 0 ? amount : null;
  }
}
