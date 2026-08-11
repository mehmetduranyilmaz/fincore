import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/presentation/constants/account_strings.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:flutter/material.dart';

final class TransactionAccountSelector extends StatelessWidget {
  const TransactionAccountSelector({
    required this.label,
    required this.accounts,
    required this.value,
    this.excludedAccountId,
    this.isRequired = true,
    this.hint = TransactionStrings.selectAccount,
    this.suffixIcon,
    required this.onChanged,
    super.key,
  });

  final String label;
  final List<Account> accounts;
  final String? value;
  final String? excludedAccountId;
  final bool isRequired;
  final String hint;
  final Widget? suffixIcon;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = accounts
        .where(
          (account) => !account.isArchived && account.id != excludedAccountId,
        )
        .toList(growable: false);
    final selectedValue = options.any((account) => account.id == value)
        ? value
        : null;

    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
      hint: Text(hint),
      items: [
        for (final account in options)
          DropdownMenuItem(
            value: account.id,
            child: Text(
              '${AccountStrings.displayName(account.name)} • '
              '${account.currencyCode}',
            ),
          ),
      ],
      onChanged: options.isEmpty ? null : onChanged,
      validator: isRequired
          ? (selection) =>
                selection == null ? TransactionStrings.requiredField : null
          : null,
    );
  }
}
