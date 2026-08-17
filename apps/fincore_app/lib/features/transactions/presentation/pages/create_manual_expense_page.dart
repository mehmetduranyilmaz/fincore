import 'dart:async';

import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:fincore_app/features/customers/presentation/controllers/customers_controller.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/presentation/controllers/categories_controller.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_selector.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_manual_expense_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_recurring_expense_plan_input.dart';
import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/create_expense_controller.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_date_field.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_source_selector.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/installment_plan_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _ExpensePaymentStatus { cash, openAccount }

enum _ExpensePlanType { oneTime, recurringMonthly }

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
  final TextEditingController _occurrenceCountController =
      TextEditingController(text: '12');

  late DateTime _transactionDate;
  ExpenseSourceSelection? _source;
  String? _categoryId;
  _ExpensePaymentStatus _paymentStatus = _ExpensePaymentStatus.cash;
  _ExpensePlanType _planType = _ExpensePlanType.oneTime;
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
    _occurrenceCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createExpenseControllerProvider);
    final accountsState = ref.watch(accountsControllerProvider);
    final creditCardsState = ref.watch(creditCardsControllerProvider);
    final customersState = ref.watch(customersControllerProvider);
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
      appBar: AppBar(
        title: const Text(TransactionStrings.createManualExpense),
        actions: [
          IconButton(
            tooltip: TransactionStrings.manageRecurringExpenses,
            onPressed: () => context.push(AppRoutes.recurringExpenses),
            icon: const Icon(Icons.event_repeat_outlined),
          ),
        ],
      ),
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
                      Text(
                        TransactionStrings.expensePlanType,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SegmentedButton<_ExpensePlanType>(
                        key: const Key('expense_plan_type'),
                        segments: const [
                          ButtonSegment(
                            value: _ExpensePlanType.oneTime,
                            label: Text(TransactionStrings.oneTimeExpense),
                            icon: Icon(Icons.looks_one_outlined),
                          ),
                          ButtonSegment(
                            value: _ExpensePlanType.recurringMonthly,
                            label: Text(
                              TransactionStrings.recurringMonthlyExpense,
                            ),
                            icon: Icon(Icons.event_repeat_outlined),
                          ),
                        ],
                        selected: {_planType},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _planType = selection.single;
                            _installmentAmounts = const [];
                            _installmentError = null;
                            final today = DateTime.now();
                            final currentMonthStart = DateTime(
                              today.year,
                              today.month,
                            );
                            if (_planType ==
                                    _ExpensePlanType.recurringMonthly &&
                                _transactionDate.isBefore(currentMonthStart)) {
                              _transactionDate = currentMonthStart;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ExpenseDateField(
                        value: _transactionDate,
                        onTap: _selectDate,
                      ),
                      if (_planType == _ExpensePlanType.recurringMonthly) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          key: const Key('recurring_occurrence_count'),
                          controller: _occurrenceCountController,
                          label: TransactionStrings.occurrenceCount,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final count = int.tryParse(value?.trim() ?? '');
                            return count == null || count < 2 || count > 60
                                ? TransactionStrings.invalidOccurrenceCount
                                : null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Expanded(
                              child: Text(
                                TransactionStrings.recurringExpenseHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        TransactionStrings.paymentStatus,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SegmentedButton<_ExpensePaymentStatus>(
                        key: const Key('expense_payment_status'),
                        segments: const [
                          ButtonSegment(
                            value: _ExpensePaymentStatus.cash,
                            label: Text(TransactionStrings.cashPayment),
                            icon: Icon(Icons.payments_outlined),
                          ),
                          ButtonSegment(
                            value: _ExpensePaymentStatus.openAccount,
                            label: Text(TransactionStrings.openAccount),
                            icon: Icon(Icons.person_outline),
                          ),
                        ],
                        selected: {_paymentStatus},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _paymentStatus = selection.single;
                            _source = null;
                            _installmentAmounts = const [];
                            _installmentError = null;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_paymentStatus == _ExpensePaymentStatus.cash) ...[
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
                        if (_planType == _ExpensePlanType.oneTime &&
                            _source?.creditCardId != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          InstallmentPlanEditor(
                            key: ValueKey('card_${_source!.creditCardId}'),
                            totalAmount: _totalAmount,
                            initialCount: 1,
                            onChanged: _installmentsChanged,
                          ),
                        ],
                      ] else ...[
                        ExpenseSourceSelector(
                          key: const Key('open_account_customer_selector'),
                          accounts: const [],
                          creditCards: const [],
                          customers: customersState.customers,
                          value: _source,
                          label: TransactionStrings.openAccountCustomer,
                          hint: TransactionStrings.selectOpenAccountCustomer,
                          onChanged: (selection) =>
                              setState(() => _source = selection),
                        ),
                        if (_planType == _ExpensePlanType.oneTime) ...[
                          const SizedBox(height: AppSpacing.md),
                          InstallmentPlanEditor(
                            key: ValueKey('customer_${_source?.customerId}'),
                            totalAmount: _totalAmount,
                            initialCount: 1,
                            onChanged: _installmentsChanged,
                          ),
                        ],
                      ],
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
                        label: _planType == _ExpensePlanType.recurringMonthly
                            ? TransactionStrings.saveRecurringExpense
                            : TransactionStrings.saveExpense,
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

    final customersStatus = ref.read(customersControllerProvider).status;
    if (customersStatus == CustomersStatus.initial ||
        customersStatus == CustomersStatus.failure) {
      unawaited(ref.read(customersControllerProvider.notifier).load());
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentMonthStart = DateTime(now.year, now.month);
    final isRecurring = _planType == _ExpensePlanType.recurringMonthly;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: isRecurring ? currentMonthStart : DateTime(2000),
      lastDate: isRecurring ? DateTime(now.year + 10, 12, 31) : today,
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
    if (_planType == _ExpensePlanType.recurringMonthly) {
      await ref
          .read(createExpenseControllerProvider.notifier)
          .createRecurring(
            CreateRecurringExpensePlanInput(
              accountId: source.accountId,
              creditCardId: source.creditCardId,
              customerId: source.customerId,
              amount: amount,
              description: description,
              categoryId: _categoryId,
              firstDueDate: _transactionDate,
              occurrenceCount: int.parse(_occurrenceCountController.text),
            ),
          );
      return;
    }
    final installmentAmounts = _installmentAmounts.length <= 1
        ? [amount]
        : _installmentAmounts;

    if (installmentAmounts.length > 1 &&
        source.creditCardId == null &&
        source.customerId == null) {
      setState(() {
        _installmentError = TransactionStrings.installmentSourceRequired;
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
            customerId: source.customerId,
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

  void _installmentsChanged(List<double> amounts) {
    _installmentAmounts = amounts;
    if (_installmentError != null && mounted) {
      setState(() => _installmentError = null);
    }
  }
}
