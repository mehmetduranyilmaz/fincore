import 'package:fincore_app/features/accounts/data/datasources/account_mock_data_source.dart';
import 'package:fincore_app/features/accounts/data/repositories/account_repository_impl.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../accounts_test_data.dart';

void main() {
  test('returns an immutable account list from the data source', () async {
    final accounts = createAccounts();
    final dataSource = _AccountDataSource(accounts);
    final repository = AccountRepositoryImpl(dataSource);

    final result = await repository.getAccounts();

    expect(result, accounts);
    expect(dataSource.callCount, 1);
    expect(() => result.add(accounts.first), throwsUnsupportedError);
  });

  test('mock data contains only supported account types', () async {
    final accounts = await const AccountMockDataSource().getAccounts();

    expect(accounts, hasLength(4));
    expect(
      accounts.map((account) => account.type),
      containsAll([
        AccountType.checking,
        AccountType.savings,
        AccountType.cash,
        AccountType.investment,
      ]),
    );
  });
}

final class _AccountDataSource implements AccountDataSource {
  _AccountDataSource(this.accounts);

  final List<Account> accounts;
  int callCount = 0;

  @override
  Future<List<Account>> getAccounts() async {
    callCount++;
    return accounts;
  }
}
