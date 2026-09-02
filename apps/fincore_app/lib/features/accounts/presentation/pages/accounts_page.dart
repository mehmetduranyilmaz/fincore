import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_empty_state.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/presentation/constants/account_strings.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/account_commands_controller.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/accounts/presentation/widgets/accounts_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

final class _AccountsPageState extends ConsumerState<AccountsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(accountsControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsControllerProvider);

    return switch (state.status) {
      AccountsStatus.initial ||
      AccountsStatus.loading => const AppLoadingView(),
      AccountsStatus.loaded => _AccountsContent(
        accounts: state.accounts,
        onCreate: () => context.push(AppRoutes.createAccount),
        onEdit: (account) =>
            context.push(AppRoutes.editAccountLocation(account.id)),
        onOpen: (account) =>
            context.push(AppRoutes.accountMovementsLocation(account.id)),
        onDelete: _confirmDelete,
      ),
      AccountsStatus.failure => AppErrorView(
        message: state.errorMessage ?? AccountStrings.unableToLoad,
        retryLabel: AccountStrings.retry,
        onRetry: ref.read(accountsControllerProvider.notifier).load,
      ),
    };
  }

  Future<void> _confirmDelete(Account account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AccountStrings.deleteTitle),
        content: Text(
          '${AccountStrings.displayName(account.name)}\n\n'
          '${AccountStrings.deleteMessage}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AccountStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AccountStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final success = await ref
        .read(accountCommandsControllerProvider.notifier)
        .delete(account.id);
    if (!mounted || success) return;
    final message = ref.read(accountCommandsControllerProvider).errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

final class _AccountsContent extends StatelessWidget {
  const _AccountsContent({
    required this.accounts,
    required this.onCreate,
    required this.onEdit,
    required this.onOpen,
    required this.onDelete,
  });

  final List<Account> accounts;
  final VoidCallback onCreate;
  final ValueChanged<Account> onEdit;
  final ValueChanged<Account> onOpen;
  final ValueChanged<Account> onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: AccountStrings.title,
            action: FilledButton.icon(
              key: const Key('create_account_button'),
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text(AccountStrings.create),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: accounts.isEmpty
                ? const AppEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: AccountStrings.noAccounts,
                    description: AccountStrings.noAccountsDescription,
                  )
                : AccountsList(
                    accounts: accounts,
                    onEdit: onEdit,
                    onOpen: onOpen,
                    onDelete: onDelete,
                  ),
          ),
        ],
      ),
    );
  }
}
