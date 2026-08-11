import 'dart:async';

import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/presentation/controllers/categories_controller.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_selector.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/entities/update_transaction_input.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/edit_transaction_controller.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_source_selector.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_account_selector.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class EditTransactionForm extends ConsumerStatefulWidget {
  const EditTransactionForm({required this.transaction, super.key});

  final Transaction transaction;

  @override
  ConsumerState<EditTransactionForm> createState() =>
      _EditTransactionFormState();
}

final class _EditTransactionFormState
    extends ConsumerState<EditTransactionForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late DateTime _transactionDate;
  late String? _accountId;
  late String? _creditCardId;
  late String? _categoryId;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _amountController = TextEditingController(
      text: AppFormatters.decimal(transaction.amount),
    );
    _descriptionController = TextEditingController(text: transaction.merchant);
    _transactionDate = transaction.transactionDate;
    _accountId = transaction.accountId;
    _creditCardId = transaction.creditCardId;
    _categoryId = transaction.categoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(editTransactionControllerProvider.notifier).reset();
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
    final editState = ref.watch(editTransactionControllerProvider);
    final accounts = ref.watch(
      accountsControllerProvider.select((state) => state.accounts),
    );
    final creditCards = ref.watch(
      creditCardsControllerProvider.select((state) => state.creditCards),
    );
    final categories = ref.watch(
      categoriesControllerProvider.select((state) => state.categories),
    );

    ref.listen<EditTransactionState>(editTransactionControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == EditTransactionStatus.success && context.mounted) {
        context.pop();
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ImmutableTransactionFields(transaction: widget.transaction),
                  const SizedBox(height: AppSpacing.md),
                  _buildPaymentSource(accounts, creditCards),
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
                    validator: (value) => value == null || value.trim().isEmpty
                        ? TransactionStrings.requiredField
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CategorySelector(
                    categories: categories,
                    type:
                        widget.transaction.transactionType ==
                            TransactionType.income
                        ? CategoryType.income
                        : CategoryType.expense,
                    value: _categoryId,
                    onChanged: (categoryId) {
                      setState(() => _categoryId = categoryId);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TransactionDateField(
                    value: _transactionDate,
                    onTap: _selectDate,
                  ),
                  if (editState.errorMessage case final message?) ...[
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
                    label: TransactionStrings.saveChanges,
                    isLoading:
                        editState.status == EditTransactionStatus.loading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSource(
    List<Account> accounts,
    List<CreditCard> creditCards,
  ) {
    if (widget.transaction.transactionType == TransactionType.income) {
      return TransactionAccountSelector(
        key: ValueKey('${_accountId ?? ''}-${accounts.length}'),
        label: TransactionStrings.account,
        accounts: accounts,
        value: _accountId,
        onChanged: (accountId) {
          setState(() {
            _accountId = accountId;
            _creditCardId = null;
          });
        },
      );
    }

    return ExpenseSourceSelector(
      key: ValueKey(
        '${_accountId ?? _creditCardId ?? ''}-'
        '${accounts.length}-${creditCards.length}',
      ),
      accounts: accounts,
      creditCards: creditCards,
      value: _expenseSelection(accounts, creditCards),
      onChanged: (selection) {
        setState(() {
          _accountId = selection?.accountId;
          _creditCardId = selection?.creditCardId;
        });
      },
    );
  }

  ExpenseSourceSelection? _expenseSelection(
    List<Account> accounts,
    List<CreditCard> creditCards,
  ) {
    if (_accountId != null) {
      for (final account in accounts) {
        if (account.id == _accountId) {
          return ExpenseSourceSelection.account(account);
        }
      }
    }
    if (_creditCardId != null) {
      for (final creditCard in creditCards) {
        if (creditCard.id == _creditCardId) {
          return ExpenseSourceSelection.creditCard(creditCard);
        }
      }
    }
    return null;
  }

  void _loadSources() {
    final accountsStatus = ref.read(accountsControllerProvider).status;
    if (accountsStatus == AccountsStatus.initial ||
        accountsStatus == AccountsStatus.failure) {
      unawaited(ref.read(accountsControllerProvider.notifier).load());
    }

    if (widget.transaction.transactionType == TransactionType.expense) {
      final creditCardsStatus = ref.read(creditCardsControllerProvider).status;
      if (creditCardsStatus == CreditCardsStatus.initial ||
          creditCardsStatus == CreditCardsStatus.failure) {
        unawaited(ref.read(creditCardsControllerProvider.notifier).load());
      }
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
        .read(editTransactionControllerProvider.notifier)
        .update(
          UpdateTransactionInput(
            transactionId: widget.transaction.id,
            accountId: _accountId,
            creditCardId: _creditCardId,
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

final class _ImmutableTransactionFields extends StatelessWidget {
  const _ImmutableTransactionFields({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        Chip(
          label: Text(
            TransactionStrings.transactionType(transaction.transactionType),
          ),
        ),
        Chip(
          label: Text(TransactionStrings.transactionSource(transaction.source)),
        ),
      ],
    );
  }
}
