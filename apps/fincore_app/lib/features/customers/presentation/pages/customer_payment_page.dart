import 'dart:async';

import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_payment_input.dart';
import 'package:fincore_app/features/customers/presentation/constants/customer_strings.dart';
import 'package:fincore_app/features/customers/presentation/controllers/customer_commands_controller.dart';
import 'package:fincore_app/features/customers/presentation/providers/customer_balance_provider.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_date_field.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_source_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CustomerPaymentPage extends ConsumerStatefulWidget {
  const CustomerPaymentPage({
    required this.customerId,
    required this.direction,
    super.key,
  });

  final String customerId;
  final CustomerPaymentDirection direction;

  @override
  ConsumerState<CustomerPaymentPage> createState() =>
      _CustomerPaymentPageState();
}

final class _CustomerPaymentPageState
    extends ConsumerState<CustomerPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _paymentDate;
  ExpenseSourceSelection? _source;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _paymentDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(accountsControllerProvider.notifier).load());
      if (widget.direction == CustomerPaymentDirection.pay) {
        unawaited(ref.read(creditCardsControllerProvider.notifier).load());
      }
      ref.read(customerCommandsControllerProvider.notifier).reset();
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
    final customer = ref.watch(customerProvider(widget.customerId));
    final accounts = ref.watch(accountsControllerProvider).accounts;
    final cards = ref.watch(creditCardsControllerProvider).creditCards;
    final command = ref.watch(customerCommandsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.direction == CustomerPaymentDirection.collect
              ? CustomerStrings.collect
              : CustomerStrings.pay,
        ),
      ),
      body: customer.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (value) {
          if (value == null) {
            return const Center(child: Text(CustomerStrings.unableToLoad));
          }
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
                        Text(
                          value.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _amountController,
                          label: CustomerStrings.amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: const [
                            TurkishDecimalInputFormatter(),
                          ],
                          validator: (text) {
                            final amount = AppFormatters.tryParseDecimal(
                              text ?? '',
                            );
                            return amount == null || amount <= 0
                                ? CustomerStrings.invalidAmount
                                : null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ExpenseSourceSelector(
                          accounts: accounts
                              .where(
                                (account) =>
                                    account.currencyCode == value.currencyCode,
                              )
                              .toList(),
                          creditCards:
                              widget.direction == CustomerPaymentDirection.pay
                              ? cards
                                    .where(
                                      (card) =>
                                          card.currencyCode ==
                                          value.currencyCode,
                                    )
                                    .toList()
                              : const [],
                          value: _source,
                          label:
                              widget.direction ==
                                  CustomerPaymentDirection.collect
                              ? CustomerStrings.receivingAccount
                              : CustomerStrings.paymentSource,
                          hint: CustomerStrings.selectPaymentSource,
                          onChanged: (selection) =>
                              setState(() => _source = selection),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _descriptionController,
                          label: CustomerStrings.description,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ExpenseDateField(
                          value: _paymentDate,
                          onTap: _selectDate,
                        ),
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
                          label: CustomerStrings.save,
                          isLoading:
                              command.status == CustomerCommandStatus.loading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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
    final source = _source!;
    final success = await ref
        .read(customerCommandsControllerProvider.notifier)
        .createCustomerPayment(
          CustomerPaymentInput(
            customerId: widget.customerId,
            direction: widget.direction,
            accountId: source.accountId,
            creditCardId: source.creditCardId,
            amount: AppFormatters.tryParseDecimal(_amountController.text)!,
            description: _descriptionController.text,
            paymentDate: _paymentDate,
          ),
        );
    if (success && mounted) context.pop();
  }
}
