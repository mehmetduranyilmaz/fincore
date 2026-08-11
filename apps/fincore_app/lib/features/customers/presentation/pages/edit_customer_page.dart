import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/entities/update_customer_input.dart';
import 'package:fincore_app/features/customers/presentation/constants/customer_strings.dart';
import 'package:fincore_app/features/customers/presentation/controllers/customer_commands_controller.dart';
import 'package:fincore_app/features/customers/presentation/providers/customer_balance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _BalanceType { receivable, payable, zero }

final class EditCustomerPage extends ConsumerWidget {
  const EditCustomerPage({required this.customerId, super.key});

  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(customerProvider(customerId));
    return Scaffold(
      appBar: AppBar(title: const Text(CustomerStrings.edit)),
      body: customer.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (value) => value == null
            ? const Center(child: Text(CustomerStrings.unableToLoad))
            : _EditCustomerForm(customer: value),
      ),
    );
  }
}

final class _EditCustomerForm extends ConsumerStatefulWidget {
  const _EditCustomerForm({required this.customer});

  final Customer customer;

  @override
  ConsumerState<_EditCustomerForm> createState() => _EditCustomerFormState();
}

final class _EditCustomerFormState extends ConsumerState<_EditCustomerForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late _BalanceType _type;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _amountController = TextEditingController(
      text: widget.customer.openingBalance == 0
          ? ''
          : AppFormatters.decimal(widget.customer.openingBalance.abs()),
    );
    _type = widget.customer.openingBalance > 0
        ? _BalanceType.receivable
        : widget.customer.openingBalance < 0
        ? _BalanceType.payable
        : _BalanceType.zero;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(customerCommandsControllerProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final command = ref.watch(customerCommandsControllerProvider);
    final hasMovements =
        ref
            .watch(customerHasMovementsProvider(widget.customer.id))
            .asData
            ?.value ??
        true;
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
                  AppTextField(
                    controller: _nameController,
                    label: CustomerStrings.name,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? CustomerStrings.required
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<_BalanceType>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: CustomerStrings.balanceType,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _BalanceType.receivable,
                        child: Text(CustomerStrings.receivable),
                      ),
                      DropdownMenuItem(
                        value: _BalanceType.payable,
                        child: Text(CustomerStrings.payable),
                      ),
                      DropdownMenuItem(
                        value: _BalanceType.zero,
                        child: Text(CustomerStrings.balanced),
                      ),
                    ],
                    onChanged: hasMovements
                        ? null
                        : (value) => setState(() => _type = value!),
                  ),
                  if (_type != _BalanceType.zero) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _amountController,
                      enabled: !hasMovements,
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

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final rawAmount = _type == _BalanceType.zero
        ? 0.0
        : AppFormatters.tryParseDecimal(_amountController.text)!;
    final openingBalance = _type == _BalanceType.payable
        ? -rawAmount
        : rawAmount;
    final success = await ref
        .read(customerCommandsControllerProvider.notifier)
        .updateCustomer(
          UpdateCustomerInput(
            customerId: widget.customer.id,
            name: _nameController.text,
            openingBalance: openingBalance,
            currencyCode: widget.customer.currencyCode,
          ),
        );
    if (success && mounted) context.pop();
  }
}
