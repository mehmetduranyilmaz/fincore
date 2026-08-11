import 'package:fincore_app/core/banking/turkish_bank.dart';
import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/core/widgets/bank_icon.dart';
import 'package:fincore_app/features/credit_cards/presentation/constants/credit_card_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final class CreditCardFormValue {
  const CreditCardFormValue({
    required this.bankName,
    required this.cardName,
    required this.lastFourDigits,
    required this.creditLimit,
    required this.statementDay,
    required this.dueDay,
    required this.currencyCode,
    required this.isArchived,
  });

  final String bankName;
  final String cardName;
  final String lastFourDigits;
  final double creditLimit;
  final int statementDay;
  final int dueDay;
  final String currencyCode;
  final bool isArchived;
}

final class CreditCardForm extends StatefulWidget {
  const CreditCardForm({
    required this.onSubmit,
    required this.onCancel,
    this.initialValue,
    this.isLoading = false,
    this.errorMessage,
    this.showArchiveOption = false,
    super.key,
  });

  final CreditCardFormValue? initialValue;
  final ValueChanged<CreditCardFormValue> onSubmit;
  final VoidCallback onCancel;
  final bool isLoading;
  final String? errorMessage;
  final bool showArchiveOption;

  @override
  State<CreditCardForm> createState() => _CreditCardFormState();
}

final class _CreditCardFormState extends State<CreditCardForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cardNameController;
  late final TextEditingController _lastFourDigitsController;
  late final TextEditingController _creditLimitController;
  late int _statementDay;
  late int _dueDay;
  late String? _bankName;
  late String _currencyCode;
  late bool _isArchived;

  @override
  void initState() {
    super.initState();
    final value = widget.initialValue;
    final selectedBank = TurkishBanks.findByName(value?.bankName);
    _bankName = selectedBank?.name ?? value?.bankName;
    _cardNameController = TextEditingController(text: value?.cardName);
    _lastFourDigitsController = TextEditingController(
      text: value?.lastFourDigits,
    );
    _creditLimitController = TextEditingController(
      text: value == null ? null : AppFormatters.decimal(value.creditLimit),
    );
    _statementDay = value?.statementDay ?? 1;
    _dueDay = value?.dueDay ?? 10;
    _currencyCode = value?.currencyCode ?? 'TRY';
    _isArchived = value?.isArchived ?? false;
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _lastFourDigitsController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banks = [...TurkishBanks.values]
      ..sort((left, right) => TurkishText.compare(left.name, right.name));
    final hasLegacyBank =
        _bankName != null && TurkishBanks.findByName(_bankName) == null;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: const Key('credit_card_bank_selector'),
            initialValue: _bankName,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: CreditCardStrings.bankName,
            ),
            hint: const Text(CreditCardStrings.selectBank),
            items: [
              if (hasLegacyBank)
                DropdownMenuItem(
                  value: _bankName,
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_outlined, size: 34),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _bankName!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              for (final bank in banks)
                DropdownMenuItem(
                  value: bank.name,
                  child: Row(
                    children: [
                      BankIcon(bank: bank, size: 34),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(bank.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
            ],
            validator: (value) =>
                value == null ? CreditCardStrings.selectBankValidation : null,
            onChanged: widget.isLoading
                ? null
                : (value) => setState(() => _bankName = value),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _cardNameController,
            label: CreditCardStrings.cardName,
            textInputAction: TextInputAction.next,
            maxLength: 80,
            validator: _requiredValidator,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _lastFourDigitsController,
            label: CreditCardStrings.lastFourDigits,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) =>
                RegExp(r'^\d{4}$').hasMatch(value?.trim() ?? '')
                ? null
                : CreditCardStrings.invalidLastFourDigits,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _creditLimitController,
            label: CreditCardStrings.creditLimit,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [TurkishDecimalInputFormatter()],
            textInputAction: TextInputAction.done,
            validator: (value) {
              final amount = AppFormatters.tryParseDecimal(value ?? '');
              return amount != null && amount.isFinite && amount > 0
                  ? null
                  : CreditCardStrings.invalidCreditLimit;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _currencyCode,
            decoration: const InputDecoration(
              labelText: CreditCardStrings.currency,
            ),
            items: const [
              DropdownMenuItem(value: 'TRY', child: Text('TRY (₺)')),
              DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
            ],
            onChanged: widget.isLoading
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _currencyCode = value);
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _dayField(isStatementDay: true)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _dayField(isStatementDay: false)),
            ],
          ),
          if (widget.showArchiveOption) ...[
            const SizedBox(height: AppSpacing.md),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(CreditCardStrings.archiveCard),
              subtitle: const Text(CreditCardStrings.archiveCardDescription),
              value: _isArchived,
              onChanged: widget.isLoading
                  ? null
                  : (value) => setState(() => _isArchived = value),
            ),
          ],
          if (widget.errorMessage case final message?) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isLoading ? null : widget.onCancel,
                  child: const Text(CreditCardStrings.cancel),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: CreditCardStrings.save,
                  isLoading: widget.isLoading,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DropdownButtonFormField<int> _dayField({required bool isStatementDay}) {
    final value = isStatementDay ? _statementDay : _dueDay;
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: isStatementDay
            ? CreditCardStrings.statementDay
            : CreditCardStrings.dueDay,
      ),
      items: [
        for (var day = 1; day <= 31; day++)
          DropdownMenuItem(value: day, child: Text('$day')),
      ],
      onChanged: widget.isLoading
          ? null
          : (newValue) {
              if (newValue == null) {
                return;
              }
              setState(() {
                if (isStatementDay) {
                  _statementDay = newValue;
                } else {
                  _dueDay = newValue;
                }
              });
            },
    );
  }

  String? _requiredValidator(String? value) {
    return value == null || value.trim().isEmpty
        ? CreditCardStrings.requiredField
        : null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final creditLimit = AppFormatters.tryParseDecimal(
      _creditLimitController.text,
    );
    if (creditLimit == null) {
      return;
    }
    widget.onSubmit(
      CreditCardFormValue(
        bankName: _bankName!,
        cardName: _cardNameController.text.trim(),
        lastFourDigits: _lastFourDigitsController.text.trim(),
        creditLimit: creditLimit,
        statementDay: _statementDay,
        dueDay: _dueDay,
        currencyCode: _currencyCode,
        isArchived: _isArchived,
      ),
    );
  }
}
