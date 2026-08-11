import 'dart:async';

import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_transfer_input.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/create_transfer_controller.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_account_selector.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_date_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreateTransferPage extends ConsumerStatefulWidget {
  const CreateTransferPage({super.key});

  @override
  ConsumerState<CreateTransferPage> createState() => _CreateTransferPageState();
}

final class _CreateTransferPageState extends ConsumerState<CreateTransferPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late DateTime _transferDate;
  String? _fromAccountId;
  String? _toAccountId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _transferDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(createTransferControllerProvider.notifier).reset();
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
    final createState = ref.watch(createTransferControllerProvider);
    final accounts = ref.watch(
      accountsControllerProvider.select((state) => state.accounts),
    );

    ref.listen<CreateTransferState>(createTransferControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == CreateTransferStatus.success && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text(TransactionStrings.createTransfer)),
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
                        key: ValueKey(
                          'from-${_fromAccountId ?? ''}-${_toAccountId ?? ''}',
                        ),
                        label: TransactionStrings.fromAccount,
                        accounts: accounts,
                        value: _fromAccountId,
                        excludedAccountId: _toAccountId,
                        onChanged: (accountId) {
                          setState(() {
                            _fromAccountId = accountId;
                            if (_toAccountId == accountId) {
                              _toAccountId = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TransactionAccountSelector(
                        key: ValueKey(
                          'to-${_toAccountId ?? ''}-${_fromAccountId ?? ''}',
                        ),
                        label: TransactionStrings.toAccount,
                        accounts: accounts,
                        value: _toAccountId,
                        excludedAccountId: _fromAccountId,
                        onChanged: (accountId) {
                          setState(() {
                            _toAccountId = accountId;
                            if (_fromAccountId == accountId) {
                              _fromAccountId = null;
                            }
                          });
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
                        value: _transferDate,
                        onTap: _selectDate,
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
                        label: TransactionStrings.saveTransfer,
                        isLoading:
                            createState.status == CreateTransferStatus.loading,
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
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _transferDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (selectedDate != null && mounted) {
      setState(() => _transferDate = selectedDate);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(createTransferControllerProvider.notifier)
        .create(
          CreateTransferInput(
            fromAccountId: _fromAccountId!,
            toAccountId: _toAccountId!,
            amount: _parseAmount(_amountController.text)!,
            description: _descriptionController.text.trim(),
            transferDate: _transferDate,
          ),
        );
  }

  double? _parseAmount(String value) {
    final amount = AppFormatters.tryParseDecimal(value);
    return amount != null && amount > 0 ? amount : null;
  }
}
