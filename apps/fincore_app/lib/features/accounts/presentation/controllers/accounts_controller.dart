import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/usecases/get_accounts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AccountsStatus { initial, loading, loaded, failure }

final class AccountsState {
  const AccountsState._({
    required this.status,
    this.accounts = const [],
    this.errorMessage,
  });

  const AccountsState.initial() : this._(status: AccountsStatus.initial);

  const AccountsState.loading() : this._(status: AccountsStatus.loading);

  AccountsState.loaded(List<Account> accounts)
    : this._(
        status: AccountsStatus.loaded,
        accounts: List.unmodifiable(accounts),
      );

  const AccountsState.failure(String message)
    : this._(status: AccountsStatus.failure, errorMessage: message);

  final AccountsStatus status;
  final List<Account> accounts;
  final String? errorMessage;
}

final accountsControllerProvider =
    NotifierProvider<AccountsController, AccountsState>(AccountsController.new);

final class AccountsController extends Notifier<AccountsState> {
  late GetAccounts _getAccounts;

  @override
  AccountsState build() {
    _getAccounts = ref.watch(getAccountsProvider);
    return const AccountsState.initial();
  }

  Future<void> load() async {
    state = const AccountsState.loading();

    try {
      final accounts = await _getAccounts.execute();
      state = AccountsState.loaded(accounts);
    } on Object catch (error) {
      state = AccountsState.failure(ErrorMapper.map(error));
    }
  }
}
