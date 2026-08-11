import 'dart:async';

import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:fincore_app/features/customers/domain/entities/update_customer_payment_input.dart';
import 'package:fincore_app/features/customers/presentation/constants/customer_strings.dart';
import 'package:fincore_app/features/customers/presentation/controllers/customer_commands_controller.dart';
import 'package:fincore_app/features/customers/presentation/providers/customer_balance_provider.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_source_selector.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class EditCustomerPaymentForm extends ConsumerStatefulWidget {
  const EditCustomerPaymentForm({required this.transaction, super.key});

  final Transaction transaction;

  @override
  ConsumerState<EditCustomerPaymentForm> createState() =>
      _EditCustomerPaymentFormState();
}

final class _EditCustomerPaymentFormState
    extends ConsumerState<EditCustomerPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late DateTime _paymentDate;
  late String? _accountId;
  late String? _creditCardId;

  bool get _isCollection => widget.transaction.customerBalanceDelta! < 0;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: AppFormatters.decimal(
        widget.transaction.customerBalanceDelta!.abs(),
      ),
    );
    _descriptionController = TextEditingController(
      text: widget.transaction.merchant,
    );
    _paymentDate = widget.transaction.transactionDate;
    _accountId = widget.transaction.accountId;
    _creditCardId = widget.transaction.creditCardId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(customerCommandsControllerProvider.notifier).reset();
      unawaited(ref.read(accountsControllerProvider.notifier).load());
      if (!_isCollection) {
        unawaited(ref.read(creditCardsControllerProvider.notifier).load());
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
    final command = ref.watch(customerCommandsControllerProvider);
    final customer = ref.watch(
      customerProvider(widget.transaction.customerId!),
    );
    final currencyCode = customer.value?.currencyCode;
    final accounts = ref
        .watch(accountsControllerProvider)
        .accounts
        .where(
          (item) => currencyCode == null || item.currencyCode == currencyCode,
        )
        .toList();
    final cards = _isCollection
        ? const <CreditCard>[]
        : ref
              .watch(creditCardsControllerProvider)
              .creditCards
              .where(
                (item) =>
                    currencyCode == null || item.currencyCode == currencyCode,
              )
              .toList();
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
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      Chip(label: Text(customer.value?.name ?? 'Müşteri')),
                      Chip(
                        label: Text(
                          _isCollection
                              ? CustomerStrings.collection
                              : CustomerStrings.payment,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ExpenseSourceSelector(
                    key: ValueKey(
                      '${_accountId ?? _creditCardId}-${accounts.length}-${cards.length}',
                    ),
                    accounts: accounts,
                    creditCards: cards,
                    value: _selection(accounts, cards),
                    label: _isCollection
                        ? CustomerStrings.receivingAccount
                        : CustomerStrings.paymentSource,
                    hint: CustomerStrings.selectPaymentSource,
                    onChanged: (selection) => setState(() {
                      _accountId = selection?.accountId;
                      _creditCardId = selection?.creditCardId;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _amountController,
                    label: CustomerStrings.amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: const [TurkishDecimalInputFormatter()],
                    validator: (text) {
                      final amount = AppFormatters.tryParseDecimal(text ?? '');
                      return amount == null || amount <= 0
                          ? CustomerStrings.invalidAmount
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _descriptionController,
                    label: CustomerStrings.description,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TransactionDateField(value: _paymentDate, onTap: _selectDate),
                  if (command.errorMessage case final message?) ...[
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
                    isLoading: command.status == CustomerCommandStatus.loading,
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

  ExpenseSourceSelection? _selection(
    List<Account> accounts,
    List<CreditCard> cards,
  ) {
    for (final account in accounts) {
      if (account.id == _accountId) {
        return ExpenseSourceSelection.account(account);
      }
    }
    for (final card in cards) {
      if (card.id == _creditCardId) {
        return ExpenseSourceSelection.creditCard(card);
      }
    }
    return null;
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) setState(() => _paymentDate = selected);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(customerCommandsControllerProvider.notifier)
        .updateCustomerPayment(
          UpdateCustomerPaymentInput(
            transactionId: widget.transaction.id,
            accountId: _accountId,
            creditCardId: _creditCardId,
            amount: AppFormatters.tryParseDecimal(_amountController.text)!,
            description: _descriptionController.text,
            paymentDate: _paymentDate,
          ),
        );
    if (success && mounted) context.pop();
  }
}
