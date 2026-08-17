import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/presentation/controllers/categories_controller.dart';
import 'package:fincore_app/features/categories/presentation/widgets/category_selector.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:fincore_app/features/customers/presentation/controllers/customers_controller.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_recurring_expense_plan_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/providers/recurring_expense_plans_provider.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_date_field.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_source_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _RecurringPaymentStatus { cash, openAccount }

final class EditRecurringExpensePlanPage extends ConsumerStatefulWidget {
  const EditRecurringExpensePlanPage({required this.planId, super.key});

  final String planId;

  @override
  ConsumerState<EditRecurringExpensePlanPage> createState() =>
      _EditRecurringExpensePlanPageState();
}

final class _EditRecurringExpensePlanPageState
    extends ConsumerState<EditRecurringExpensePlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _occurrenceCountController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  RecurringExpensePlan? _plan;
  ExpenseSourceSelection? _source;
  String? _categoryId;
  late DateTime _firstDueDate;
  _RecurringPaymentStatus _paymentStatus = _RecurringPaymentStatus.cash;

  @override
  void initState() {
    super.initState();
    _firstDueDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
    final accounts = ref.watch(accountsControllerProvider).accounts;
    final cards = ref.watch(creditCardsControllerProvider).creditCards;
    final customers = ref.watch(customersControllerProvider).customers;
    final categories = ref.watch(categoriesControllerProvider).categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text(TransactionStrings.editRecurringExpense),
      ),
      body: _loading
          ? const AppLoadingView()
          : _plan == null
          ? const AppEmptyState(
              icon: Icons.event_busy_outlined,
              title: TransactionStrings.notFound,
              description: TransactionStrings.notFoundDescription,
            )
          : SafeArea(
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: const [
                                TurkishDecimalInputFormatter(),
                              ],
                              validator: (value) => _parseAmount(value) == null
                                  ? TransactionStrings.invalidAmount
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _descriptionController,
                              label: TransactionStrings.description,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? TransactionStrings.requiredField
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ExpenseDateField(
                              value: _firstDueDate,
                              onTap: _selectDate,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
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
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              TransactionStrings.paymentStatus,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            SegmentedButton<_RecurringPaymentStatus>(
                              segments: const [
                                ButtonSegment(
                                  value: _RecurringPaymentStatus.cash,
                                  label: Text(TransactionStrings.cashPayment),
                                  icon: Icon(Icons.payments_outlined),
                                ),
                                ButtonSegment(
                                  value: _RecurringPaymentStatus.openAccount,
                                  label: Text(TransactionStrings.openAccount),
                                  icon: Icon(Icons.person_outline),
                                ),
                              ],
                              selected: {_paymentStatus},
                              onSelectionChanged: (selection) => setState(() {
                                _paymentStatus = selection.single;
                                _source = null;
                              }),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (_paymentStatus == _RecurringPaymentStatus.cash)
                              ExpenseSourceSelector(
                                accounts: accounts,
                                creditCards: cards,
                                value: _source,
                                onChanged: (value) =>
                                    setState(() => _source = value),
                              )
                            else
                              ExpenseSourceSelector(
                                accounts: const [],
                                creditCards: const [],
                                customers: customers,
                                value: _source,
                                label: TransactionStrings.openAccountCustomer,
                                hint: TransactionStrings
                                    .selectOpenAccountCustomer,
                                onChanged: (value) =>
                                    setState(() => _source = value),
                              ),
                            const SizedBox(height: AppSpacing.md),
                            CategorySelector(
                              categories: categories,
                              type: CategoryType.expense,
                              value: _categoryId,
                              onChanged: (value) =>
                                  setState(() => _categoryId = value),
                            ),
                            if (_errorMessage case final message?) ...[
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
                              isLoading: _saving,
                              onPressed: _save,
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

  Future<void> _load() async {
    try {
      await Future.wait([
        ref.read(accountsControllerProvider.notifier).load(),
        ref.read(creditCardsControllerProvider.notifier).load(),
        ref.read(customersControllerProvider.notifier).load(),
        ref.read(categoriesControllerProvider.notifier).load(),
      ]);
      final plan = await ref.read(
        recurringExpensePlanProvider(widget.planId).future,
      );
      if (!mounted) return;
      if (plan == null) {
        setState(() => _loading = false);
        return;
      }
      _amountController.text = plan.amount
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _descriptionController.text = plan.description;
      _occurrenceCountController.text = plan.occurrenceCount.toString();
      _paymentStatus = plan.customerId == null
          ? _RecurringPaymentStatus.cash
          : _RecurringPaymentStatus.openAccount;
      _source = _resolveSource(plan);
      setState(() {
        _plan = plan;
        _firstDueDate = plan.firstDueDate;
        _categoryId = plan.categoryId;
        _loading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = ErrorMapper.map(error);
        });
      }
    }
  }

  ExpenseSourceSelection? _resolveSource(RecurringExpensePlan plan) {
    for (final account in ref.read(accountsControllerProvider).accounts) {
      if (account.id == plan.accountId) {
        return ExpenseSourceSelection.account(account);
      }
    }
    for (final card in ref.read(creditCardsControllerProvider).creditCards) {
      if (card.id == plan.creditCardId) {
        return ExpenseSourceSelection.creditCard(card);
      }
    }
    for (final customer in ref.read(customersControllerProvider).customers) {
      if (customer.id == plan.customerId) {
        return ExpenseSourceSelection.customer(customer);
      }
    }
    return null;
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _firstDueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10, 12, 31),
    );
    if (selected != null && mounted) {
      setState(() => _firstDueDate = selected);
    }
  }

  Future<void> _save() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    final source = _source;
    if (source == null) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(updateRecurringExpensePlanProvider)
          .execute(
            widget.planId,
            CreateRecurringExpensePlanInput(
              accountId: source.accountId,
              creditCardId: source.creditCardId,
              customerId: source.customerId,
              amount: _parseAmount(_amountController.text)!,
              description: _descriptionController.text,
              categoryId: _categoryId,
              firstDueDate: _firstDueDate,
              occurrenceCount: int.parse(_occurrenceCountController.text),
            ),
          );
      ref.invalidate(recurringExpensePlansProvider);
      ref.invalidate(recurringExpensePlanProvider(widget.planId));
      ref.read(appDataRefreshCoordinatorProvider).recurringExpensePlanChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(TransactionStrings.recurringExpenseUpdated),
          ),
        );
        context.pop();
      }
    } on Object catch (error) {
      if (mounted) setState(() => _errorMessage = ErrorMapper.map(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static double? _parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final normalized = value.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(normalized);
    return amount == null || !amount.isFinite || amount <= 0 ? null : amount;
  }
}
