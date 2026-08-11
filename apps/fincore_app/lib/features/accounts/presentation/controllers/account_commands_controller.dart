import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/accounts/domain/entities/create_account_input.dart';
import 'package:fincore_app/features/accounts/domain/entities/update_account_input.dart';
import 'package:fincore_app/features/accounts/domain/errors/account_operation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AccountCommandStatus { initial, loading, success, failure }

final class AccountCommandState {
  const AccountCommandState._({required this.status, this.errorMessage});
  const AccountCommandState.initial()
    : this._(status: AccountCommandStatus.initial);
  const AccountCommandState.loading()
    : this._(status: AccountCommandStatus.loading);
  const AccountCommandState.success()
    : this._(status: AccountCommandStatus.success);
  const AccountCommandState.failure(String message)
    : this._(status: AccountCommandStatus.failure, errorMessage: message);

  final AccountCommandStatus status;
  final String? errorMessage;
}

final accountCommandsControllerProvider =
    NotifierProvider<AccountCommandsController, AccountCommandState>(
      AccountCommandsController.new,
    );

final class AccountCommandsController extends Notifier<AccountCommandState> {
  @override
  AccountCommandState build() => const AccountCommandState.initial();

  Future<bool> create(CreateAccountInput input) async {
    return _execute(() async {
      final account = await ref.read(createAccountProvider).execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .accountChanged(account.id);
    });
  }

  Future<bool> update(UpdateAccountInput input) async {
    return _execute(() async {
      final account = await ref.read(updateAccountProvider).execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .accountChanged(account.id);
    });
  }

  Future<bool> delete(String accountId) async {
    return _execute(() async {
      await ref.read(deleteAccountProvider).execute(accountId);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .accountChanged(accountId);
    });
  }

  Future<bool> _execute(Future<void> Function() action) async {
    state = const AccountCommandState.loading();
    try {
      await action();
      state = const AccountCommandState.success();
      return true;
    } on AccountOperationException catch (error) {
      state = AccountCommandState.failure(error.message);
      return false;
    } on Object catch (error) {
      state = AccountCommandState.failure(ErrorMapper.map(error));
      return false;
    }
  }

  void reset() => state = const AccountCommandState.initial();
}
