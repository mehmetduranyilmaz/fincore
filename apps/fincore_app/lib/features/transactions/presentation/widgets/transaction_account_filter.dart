import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/transactions/presentation/constants/transaction_strings.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transaction_filter_controller.dart';
import 'package:fincore_app/features/transactions/presentation/widgets/transaction_account_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class TransactionAccountFilter extends ConsumerWidget {
  const TransactionAccountFilter({required this.accounts, super.key});

  final List<Account> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = ref.watch(
      transactionFilterControllerProvider.select((filter) => filter.accountId),
    );

    return SizedBox(
      width: 280,
      child: TransactionAccountSelector(
        key: ValueKey(accountId),
        label: TransactionStrings.account,
        hint: TransactionStrings.clearAccountFilter,
        accounts: accounts,
        value: accountId,
        isRequired: false,
        suffixIcon: accountId == null
            ? null
            : IconButton(
                tooltip: TransactionStrings.clearAccountFilter,
                onPressed: () => ref
                    .read(transactionFilterControllerProvider.notifier)
                    .setAccountId(null),
                icon: const Icon(Icons.close),
              ),
        onChanged: ref
            .read(transactionFilterControllerProvider.notifier)
            .setAccountId,
      ),
    );
  }
}
