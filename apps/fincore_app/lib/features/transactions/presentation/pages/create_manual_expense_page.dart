import 'dart:async';

import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/presentation/controllers/categories_controller.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_selector.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_manual_expense_input.dart';
import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/create_expense_controller.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_date_field.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_source_selector.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/installment_plan_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreateManualExpensePage extends ConsumerStatefulWidget {
  const CreateManualExpensePage({super.key});

  @override
  ConsumerState<CreateManualExpensePage> createState() =>
      _CreateManualExpensePageState();
}

final class _CreateManualExpensePageState
    extends ConsumerState<CreateManualExpensePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late DateTime _transactionDate;
  ExpenseSourceSelection? _source;
  String? _categoryId;
  double _totalAmount = 0;
  List<double> _installmentAmounts = const [];
  String? _installmentError;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _transactionDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(createExpenseControllerProvider.notifier).reset();
        _loadSources();
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
    final createState = ref.watch(createExpenseControllerProvider);
    final accountsState = ref.watch(accountsControllerProvider);
    final creditCardsState = ref.watch(creditCardsControllerProvider);
    final categories = ref.watch(
      categoriesControllerProvider.select((state) => state.categories),
    );

    ref.listen<CreateExpenseState>(createExpenseControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == CreateExpenseStatus.success && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(TransactionStrings.createManualExpense)),
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
                        onChanged: (value) {
                          setState(() {
                            _totalAmount = _parseAmount(value) ?? 0;
                            _installmentError = null;
                          });
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
                      ExpenseDateField(
                        value: _transactionDate,
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ExpenseSourceSelector(
                        accounts: accountsState.accounts,
                        creditCards: creditCardsState.creditCards,
                        value: _source,
                        onChanged: (selection) {
                          setState(() {
                            _source = selection;
                            _installmentError = null;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InstallmentPlanEditor(
                        totalAmount: _totalAmount,
                        initialCount: 1,
                        onChanged: (amounts) {
                          _installmentAmounts = amounts;
                          if (_installmentError != null && mounted) {
                            setState(() => _installmentError = null);
                          }
                        },
                      ),
                      if (_installmentError case final message?) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      CategorySelector(
                        categories: categories,
                        type: CategoryType.expense,
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
                        label: TransactionStrings.saveExpense,
                        isLoading:
                            createState.status == CreateExpenseStatus.loading,
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

  void _loadSources() {
    final accountsStatus = ref.read(accountsControllerProvider).status;
    if (accountsStatus == AccountsStatus.initial ||
        accountsStatus == AccountsStatus.failure) {
      unawaited(ref.read(accountsControllerProvider.notifier).load());
    }

    final creditCardsStatus = ref.read(creditCardsControllerProvider).status;
    if (creditCardsStatus == CreditCardsStatus.initial ||
        creditCardsStatus == CreditCardsStatus.failure) {
      unawaited(ref.read(creditCardsControllerProvider.notifier).load());
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

    final amount = _parseAmount(_amountController.text)!;
    final description = _descriptionController.text.trim();
    final source = _source!;
    final installmentAmounts = _installmentAmounts.length <= 1
        ? [amount]
        : _installmentAmounts;

    if (installmentAmounts.length > 1 && source.creditCardId == null) {
      setState(() {
        _installmentError = TransactionStrings.installmentCardRequired;
      });
      return;
    }
    if (installmentAmounts.length > 1) {
      try {
        InstallmentCalculator.validateCustomAmounts(amount, installmentAmounts);
      } on ArgumentError {
        setState(() {
          _installmentError = TransactionStrings.installmentTotalMismatch;
        });
        return;
      }
    }

    await ref
        .read(createExpenseControllerProvider.notifier)
        .create(
          CreateManualExpenseInput(
            accountId: source.accountId,
            creditCardId: source.creditCardId,
            amount: amount,
            description: description,
            categoryId: _categoryId,
            transactionDate: _transactionDate,
            installmentAmounts: installmentAmounts,
          ),
        );
  }

  double? _parseAmount(String value) {
    final amount = AppFormatters.tryParseDecimal(value);
    return amount != null && amount > 0 ? amount : null;
  }
}
