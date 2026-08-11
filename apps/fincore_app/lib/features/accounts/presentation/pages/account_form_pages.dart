import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:fincore_app/core/banking/turkish_bank.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:fincore_app/core/widgets/app_card.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_text_field.dart';
import 'package:fincore_app/core/widgets/bank_icon.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/entities/create_account_input.dart';
import 'package:fincore_app/features/accounts/domain/entities/update_account_input.dart';
import 'package:fincore_app/features/accounts/presentation/constants/account_strings.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/account_commands_controller.dart';
import 'package:fincore_app/features/accounts/presentation/formatters/turkish_iban_input_formatter.dart';
import 'package:fincore_app/features/accounts/presentation/providers/account_balance_provider.dart';
import 'package:fincore_app/features/accounts/domain/value_objects/turkish_iban.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _AccountAppBar(title: AccountStrings.create),
      body: _AccountForm(),
    );
  }
}

final class EditAccountPage extends ConsumerWidget {
  const EditAccountPage({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider(accountId));
    return Scaffold(
      appBar: const _AccountAppBar(title: AccountStrings.edit),
      body: account.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => Center(child: Text(error.toString())),
        data: (value) => value == null
            ? const Center(child: Text(AccountStrings.unableToLoad))
            : _AccountForm(account: value),
      ),
    );
  }
}

final class _AccountAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _AccountAppBar({required this.title});
  final String title;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(title: Text(title));
}

final class _AccountForm extends ConsumerStatefulWidget {
  const _AccountForm({this.account});
  final Account? account;

  @override
  ConsumerState<_AccountForm> createState() => _AccountFormState();
}

final class _AccountFormState extends ConsumerState<_AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _ibanController;
  late AccountType _type;
  late String _currencyCode;
  late String? _bankId;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController = TextEditingController(text: account?.name ?? '');
    _balanceController = TextEditingController(
      text: AppFormatters.decimal(account?.openingBalance ?? 0),
    );
    _ibanController = TextEditingController(
      text: account?.iban == null ? '' : TurkishIban.format(account!.iban!),
    );
    _type = account?.type ?? AccountType.checking;
    _currencyCode = account?.currencyCode ?? 'TRY';
    _bankId = account?.bankId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(accountCommandsControllerProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final command = ref.watch(accountCommandsControllerProvider);
    final banks = [...TurkishBanks.values]
      ..sort((left, right) => TurkishText.compare(left.name, right.name));
    final hasMovements = widget.account == null
        ? false
        : ref
                  .watch(accountHasMovementsProvider(widget.account!.id))
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
                    label: AccountStrings.name,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? AccountStrings.required
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<AccountType>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: AccountStrings.type,
                    ),
                    items: [
                      for (final type in AccountType.values)
                        DropdownMenuItem(
                          value: type,
                          child: Text(AccountStrings.accountType(type)),
                        ),
                    ],
                    onChanged: hasMovements
                        ? null
                        : (value) => setState(() {
                            _type = value!;
                            if (_type == AccountType.cash) {
                              _bankId = null;
                              _ibanController.clear();
                            }
                          }),
                  ),
                  if (_type != AccountType.cash) ...[
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _bankId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: AccountStrings.bank,
                      ),
                      hint: const Text(AccountStrings.selectBank),
                      items: [
                        for (final bank in banks)
                          DropdownMenuItem(
                            value: bank.id,
                            child: Row(
                              children: [
                                BankIcon(bank: bank, size: 34),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    bank.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      validator: (value) =>
                          value == null ? AccountStrings.selectBank : null,
                      onChanged: (value) => setState(() => _bankId = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _ibanController,
                      label: AccountStrings.iban,
                      hint: AccountStrings.ibanHint,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: const [TurkishIbanInputFormatter()],
                      maxLength: 32,
                      validator: (value) {
                        final iban = value?.trim() ?? '';
                        return iban.isNotEmpty && !TurkishIban.isValid(iban)
                            ? AccountStrings.invalidIban
                            : null;
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _currencyCode,
                    decoration: const InputDecoration(
                      labelText: AccountStrings.currency,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'TRY', child: Text('TRY - ₺')),
                      DropdownMenuItem(value: 'USD', child: Text('USD - \$')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR - €')),
                    ],
                    onChanged: hasMovements
                        ? null
                        : (value) => setState(() => _currencyCode = value!),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _balanceController,
                    enabled: !hasMovements,
                    label: AccountStrings.openingBalance,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    inputFormatters: const [
                      TurkishDecimalInputFormatter(allowNegative: true),
                    ],
                    validator: (value) =>
                        AppFormatters.tryParseDecimal(value ?? '') == null
                        ? AccountStrings.invalidAmount
                        : null,
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
                    label: AccountStrings.save,
                    isLoading: command.status == AccountCommandStatus.loading,
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
    final openingBalance = AppFormatters.tryParseDecimal(
      _balanceController.text,
    )!;
    final notifier = ref.read(accountCommandsControllerProvider.notifier);
    final success = widget.account == null
        ? await notifier.create(
            CreateAccountInput(
              name: _nameController.text,
              type: _type,
              currencyCode: _currencyCode,
              openingBalance: openingBalance,
              bankId: _bankId,
              iban: _ibanController.text,
            ),
          )
        : await notifier.update(
            UpdateAccountInput(
              accountId: widget.account!.id,
              name: _nameController.text,
              type: _type,
              currencyCode: _currencyCode,
              openingBalance: openingBalance,
              bankId: _bankId,
              iban: _ibanController.text,
            ),
          );
    if (success && mounted) context.pop();
  }
}
