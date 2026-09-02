import 'package:fincore_app/core/banking/turkish_bank.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_card.dart' as design_system;
import 'package:fincore_app/core/widgets/bank_icon.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/value_objects/turkish_iban.dart';
import 'package:fincore_app/features/accounts/presentation/constants/account_strings.dart';
import 'package:fincore_app/features/accounts/presentation/providers/account_balance_provider.dart';
import 'package:fincore_app/features/accounts/presentation/widgets/account_balance_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AccountCard extends ConsumerWidget {
  const AccountCard({
    required this.account,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    super.key,
  });

  final Account account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final balance = ref.watch(accountBalanceProvider(account.id));

    return design_system.AppCard(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = _AccountDetails(
            account: account,
            onEdit: onEdit,
            onDelete: onDelete,
          );
          final summary = balance.when(
            loading: () => const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (error, stackTrace) => Text(
              AccountStrings.balanceUnavailable,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            data: (value) => AccountBalanceSummary(
              balance: value,
              currencyCode: account.currencyCode,
            ),
          );

          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: AppSpacing.md),
                Align(alignment: Alignment.centerRight, child: summary),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: details),
              const SizedBox(width: AppSpacing.md),
              summary,
            ],
          );
        },
      ),
    );
  }
}

final class _AccountDetails extends StatelessWidget {
  const _AccountDetails({
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  final Account account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bank = TurkishBanks.findById(account.bankId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bank != null) ...[
          BankIcon(bank: bank),
          const SizedBox(width: AppSpacing.sm),
        ] else ...[
          const Icon(Icons.account_balance_wallet_outlined, size: 42),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AccountStrings.displayName(account.name),
                style: textTheme.titleMedium,
              ),
              if (bank != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(bank.name, style: textTheme.bodyMedium),
              ],
              if (account.iban case final iban?) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(TurkishIban.format(iban), style: textTheme.bodySmall),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                AccountStrings.accountType(account.type),
                style: textTheme.bodyMedium,
              ),
              if (account.isArchived) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(AccountStrings.archived, style: textTheme.labelMedium),
              ],
            ],
          ),
        ),
        Column(
          children: [
            IconButton(
              key: Key('edit_account_${account.id}'),
              tooltip: AccountStrings.edit,
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              key: Key('delete_account_${account.id}'),
              tooltip: AccountStrings.delete,
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    );
  }
}
