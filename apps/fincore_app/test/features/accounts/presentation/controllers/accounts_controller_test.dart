import 'dart:async';

import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../accounts_test_data.dart';

void main() {
  test('moves from initial to loading and loaded', () async {
    final completer = Completer<List<Account>>();
    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(
          _AccountRepository(completer.future),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(accountsControllerProvider).status,
      AccountsStatus.initial,
    );

    final load = container.read(accountsControllerProvider.notifier).load();

    expect(
      container.read(accountsControllerProvider).status,
      AccountsStatus.loading,
    );

    final accounts = createAccounts();
    completer.complete(accounts);
    await load;

    final state = container.read(accountsControllerProvider);

    expect(state.status, AccountsStatus.loaded);
    expect(state.accounts, accounts);
    expect(() => state.accounts.add(accounts.first), throwsUnsupportedError);
    expect(state.errorMessage, isNull);
  });

  test('moves to failure when the repository throws', () async {
    final container = ProviderContainer(
      overrides: [
        accountRepositoryProvider.overrideWithValue(
          _AccountRepository(Future.error(Exception('Failed'))),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(accountsControllerProvider.notifier).load();

    final state = container.read(accountsControllerProvider);

    expect(state.status, AccountsStatus.failure);
    expect(state.accounts, isEmpty);
    expect(state.errorMessage, isNotEmpty);
  });
}

final class _AccountRepository implements AccountRepository {
  const _AccountRepository(this.result);

  final Future<List<Account>> result;

  @override
  Future<List<Account>> getAccounts() => result;
}
