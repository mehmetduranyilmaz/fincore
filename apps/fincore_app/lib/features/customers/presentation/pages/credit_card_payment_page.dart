import 'dart:async';

import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_balance_provider.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_statements_provider.dart';
import 'package:fincore_app/features/customers/domain/entities/credit_card_payment_input.dart';
import 'package:fincore_app/features/customers/presentation/constants/customer_strings.dart';
import 'package:fincore_app/features/customers/presentation/controllers/customer_commands_controller.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/expense_date_field.dart';
import 'package:fincore_app/features/transactions/presentation/formatters/payment_source_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreditCardPaymentPage extends ConsumerStatefulWidget {
  const CreditCardPaymentPage({
    required this.creditCardId,
    this.statementId,
    super.key,
  });

  final String creditCardId;
  final String? statementId;

  @override
  ConsumerState<CreditCardPaymentPage> createState() =>
      _CreditCardPaymentPageState();
}

final class _CreditCardPaymentPageState
    extends ConsumerState<CreditCardPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _paymentDate;
  String? _accountId;
  bool _statementAmountApplied = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _paymentDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(accountsControllerProvider.notifier).load());
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
    final card = ref.watch(creditCardProvider(widget.creditCardId));
    final balance = ref.watch(creditCardBalanceProvider(widget.creditCardId));
    final statementStatus = widget.statementId == null
        ? null
        : ref.watch(
            creditCardStatementPaymentStatusProvider((
              creditCardId: widget.creditCardId,
              statementId: widget.statementId!,
            )),
          );
    final loadedStatementStatus = statementStatus?.value;
    if (!_statementAmountApplied && loadedStatementStatus != null) {
      _statementAmountApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _amountController.text.isNotEmpty) return;
        _amountController.text = AppFormatters.decimal(
          loadedStatementStatus.remainingAmount,
        );
      });
    }
    final accounts = ref.watch(accountsControllerProvider).accounts;
    final command = ref.watch(customerCommandsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.statementId == null
              ? CustomerStrings.cardPayment
              : 'Ekstre Ödemesi',
        ),
      ),
      body: card.when(
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
                          '${value.bankName} ${value.cardName} ••••${value.lastFourDigits}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        balance.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (item) => Text(
                            'Güncel Borç: ${AppFormatters.currency(item.currentDebt, currencyCode: value.currencyCode)}',
                          ),
                        ),
                        if (statementStatus != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          statementStatus.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => Text(
                              'Ekstre ödeme bilgileri yüklenemedi.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            data: (status) => AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    '${AppFormatters.date(status.statement.statementDate)} ekstresi',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Ekstre: ${AppFormatters.currency(status.statement.totalAmount, currencyCode: value.currencyCode)}',
                                  ),
                                  Text(
                                    'Ödenen: ${AppFormatters.currency(status.paidAmount, currencyCode: value.currencyCode)}',
                                  ),
                                  Text(
                                    'Kalan: ${AppFormatters.currency(status.remainingAmount, currencyCode: value.currencyCode)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          initialValue: _accountId,
                          decoration: const InputDecoration(
                            labelText: CustomerStrings.fromAccount,
                          ),
                          items: [
                            for (final account in accounts)
                              if (!account.isArchived &&
                                  account.currencyCode == value.currencyCode)
                                DropdownMenuItem(
                                  value: account.id,
                                  child: Text(
                                    '${PaymentSourceFormatter.account(account)} • ${account.name}',
                                  ),
                                ),
                          ],
                          validator: (value) =>
                              value == null ? CustomerStrings.required : null,
                          onChanged: (value) =>
                              setState(() => _accountId = value),
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
                          onPressed:
                              statementStatus?.isLoading == true ||
                                  loadedStatementStatus?.isPaid == true
                              ? null
                              : _submit,
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
    final success = await ref
        .read(customerCommandsControllerProvider.notifier)
        .createCreditCardPayment(
          CreditCardPaymentInput(
            creditCardId: widget.creditCardId,
            fromAccountId: _accountId!,
            amount: AppFormatters.tryParseDecimal(_amountController.text)!,
            description: _descriptionController.text,
            paymentDate: _paymentDate,
            statementId: widget.statementId,
          ),
        );
    if (success && mounted) context.pop();
  }
}
