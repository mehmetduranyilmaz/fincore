import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/presentation/widgets/account_card.dart';
import 'package:flutter/material.dart';

final class AccountsList extends StatelessWidget {
  const AccountsList({
    required this.accounts,
    required this.onEdit,
    required this.onOpen,
    required this.onDelete,
    super.key,
  });

  static const double _gridBreakpoint = 720;

  final List<Account> accounts;
  final ValueChanged<Account> onEdit;
  final ValueChanged<Account> onOpen;
  final ValueChanged<Account> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _gridBreakpoint) {
          return ListView.separated(
            key: const Key('accounts_list_layout'),
            itemCount: accounts.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => AccountCard(
              account: accounts[index],
              onTap: () => onOpen(accounts[index]),
              onEdit: () => onEdit(accounts[index]),
              onDelete: () => onDelete(accounts[index]),
            ),
          );
        }

        return GridView.builder(
          key: const Key('accounts_grid_layout'),
          itemCount: accounts.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 480,
            mainAxisExtent: 280,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
          ),
          itemBuilder: (context, index) => AccountCard(
            account: accounts[index],
            onTap: () => onOpen(accounts[index]),
            onEdit: () => onEdit(accounts[index]),
            onDelete: () => onDelete(accounts[index]),
          ),
        );
      },
    );
  }
}
