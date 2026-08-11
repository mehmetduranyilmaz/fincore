import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/customers/domain/entities/create_customer_input.dart';
import 'package:fincore_app/features/customers/presentation/constants/customer_strings.dart';
import 'package:fincore_app/features/customers/presentation/controllers/customer_commands_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _OpeningBalanceType { receivable, payable, zero }

final class CreateCustomerPage extends ConsumerStatefulWidget {
  const CreateCustomerPage({super.key});

  @override
  ConsumerState<CreateCustomerPage> createState() => _CreateCustomerPageState();
}

final class _CreateCustomerPageState extends ConsumerState<CreateCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  _OpeningBalanceType _type = _OpeningBalanceType.receivable;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerCommandsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(CustomerStrings.add)),
      body: SingleChildScrollView(
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
                    AppTextField(
                      controller: _nameController,
                      label: CustomerStrings.name,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? CustomerStrings.required
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<_OpeningBalanceType>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: CustomerStrings.balanceType,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: _OpeningBalanceType.receivable,
                          child: Text(CustomerStrings.receivable),
                        ),
                        DropdownMenuItem(
                          value: _OpeningBalanceType.payable,
                          child: Text(CustomerStrings.payable),
                        ),
                        DropdownMenuItem(
                          value: _OpeningBalanceType.zero,
                          child: Text(CustomerStrings.balanced),
                        ),
                      ],
                      onChanged: (value) => setState(() => _type = value!),
                    ),
                    if (_type != _OpeningBalanceType.zero) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _amountController,
                        label: CustomerStrings.openingBalance,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: const [TurkishDecimalInputFormatter()],
                        validator: (value) {
                          final amount = AppFormatters.tryParseDecimal(
                            value ?? '',
                          );
                          return amount == null || amount <= 0
                              ? CustomerStrings.invalidAmount
                              : null;
                        },
                      ),
                    ],
                    if (state.errorMessage case final message?) ...[
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
                      isLoading: state.status == CustomerCommandStatus.loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rawAmount = _type == _OpeningBalanceType.zero
        ? 0.0
        : AppFormatters.tryParseDecimal(_amountController.text)!;
    final openingBalance = _type == _OpeningBalanceType.payable
        ? -rawAmount
        : rawAmount;
    final success = await ref
        .read(customerCommandsControllerProvider.notifier)
        .createCustomer(
          CreateCustomerInput(
            name: _nameController.text,
            openingBalance: openingBalance,
            currencyCode: 'TRY',
          ),
        );
    if (success && mounted) context.pop();
  }
}
