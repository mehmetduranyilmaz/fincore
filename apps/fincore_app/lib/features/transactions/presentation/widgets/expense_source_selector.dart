import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/presentation/constants/account_strings.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/formatters/payment_source_formatter.dart';
import 'package:flutter/material.dart';

final class ExpenseSourceSelection {
  const ExpenseSourceSelection._({
    required this.accountId,
    required this.creditCardId,
    required this.customerId,
    required this.label,
    required this.description,
    required this.kind,
  });

  factory ExpenseSourceSelection.account(Account account) {
    return ExpenseSourceSelection._(
      accountId: account.id,
      creditCardId: null,
      customerId: null,
      label: PaymentSourceFormatter.account(account),
      description: AccountStrings.displayName(account.name),
      kind: account.type == AccountType.cash
          ? ExpenseSourceKind.cash
          : ExpenseSourceKind.bankAccount,
    );
  }

  factory ExpenseSourceSelection.creditCard(CreditCard creditCard) {
    return ExpenseSourceSelection._(
      accountId: null,
      creditCardId: creditCard.id,
      customerId: null,
      label: PaymentSourceFormatter.creditCard(creditCard),
      description: creditCard.cardName,
      kind: ExpenseSourceKind.creditCard,
    );
  }

  factory ExpenseSourceSelection.customer(Customer customer) {
    final currency = customer.currencyCode == 'TRY'
        ? 'TL'
        : customer.currencyCode;
    return ExpenseSourceSelection._(
      accountId: null,
      creditCardId: null,
      customerId: customer.id,
      label: 'AH-${customer.name}',
      description: '$currency • Açık hesap',
      kind: ExpenseSourceKind.openAccount,
    );
  }

  final String? accountId;
  final String? creditCardId;
  final String? customerId;
  final String label;
  final String description;
  final ExpenseSourceKind kind;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExpenseSourceSelection &&
            accountId == other.accountId &&
            creditCardId == other.creditCardId &&
            customerId == other.customerId;
  }

  @override
  int get hashCode => Object.hash(accountId, creditCardId, customerId);
}

enum ExpenseSourceKind { bankAccount, cash, creditCard, openAccount }

final class ExpenseSourceSelector extends StatelessWidget {
  const ExpenseSourceSelector({
    required this.accounts,
    required this.creditCards,
    this.customers = const [],
    required this.value,
    required this.onChanged,
    this.label = TransactionStrings.paymentSource,
    this.hint = TransactionStrings.selectPaymentSource,
    super.key,
  });

  final List<Account> accounts;
  final List<CreditCard> creditCards;
  final List<Customer> customers;
  final ExpenseSourceSelection? value;
  final ValueChanged<ExpenseSourceSelection?> onChanged;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final account in accounts.where((account) => !account.isArchived))
        ExpenseSourceSelection.account(account),
      for (final creditCard in creditCards.where(
        (creditCard) => !creditCard.isArchived,
      ))
        ExpenseSourceSelection.creditCard(creditCard),
      for (final customer in customers.where(
        (customer) => !customer.isArchived,
      ))
        ExpenseSourceSelection.customer(customer),
    ];

    return DropdownButtonFormField<ExpenseSourceSelection>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 360,
      itemHeight: 64,
      decoration: InputDecoration(labelText: label),
      hint: Text(hint),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: _ExpenseSourceOption(option: option),
          ),
      ],
      selectedItemBuilder: (context) => [
        for (final option in options)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
      onChanged: options.isEmpty ? null : onChanged,
      validator: (selection) =>
          selection == null ? TransactionStrings.requiredField : null,
    );
  }
}

final class _ExpenseSourceOption extends StatelessWidget {
  const _ExpenseSourceOption({required this.option});

  final ExpenseSourceSelection option;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (option.kind) {
      ExpenseSourceKind.bankAccount => Icons.account_balance_outlined,
      ExpenseSourceKind.cash => Icons.account_balance_wallet_outlined,
      ExpenseSourceKind.creditCard => Icons.credit_card_outlined,
      ExpenseSourceKind.openAccount => Icons.person_outline,
    };

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 20, color: colors.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                option.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
