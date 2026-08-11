import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';

abstract interface class AccountDataSource {
  Future<List<Account>> getAccounts();
}

abstract interface class AccountCommandDataSource {
  Future<Account?> getById(String accountId);

  Future<void> insert(Account account);

  Future<void> replace(Account account);

  Future<void> archive(String accountId);
}

final class AccountMockDataSource implements AccountDataSource {
  const AccountMockDataSource();

  @override
  Future<List<Account>> getAccounts() async {
    return List.unmodifiable(defaultAccounts);
  }

  static const List<Account> defaultAccounts = [
    Account(
      id: 'account-1',
      name: 'Primary Account',
      type: AccountType.checking,
      currencyCode: 'TRY',
      isArchived: false,
    ),
    Account(
      id: 'account-2',
      name: 'Savings',
      type: AccountType.savings,
      currencyCode: 'TRY',
      isArchived: false,
    ),
    Account(
      id: 'account-4',
      name: 'USD Account',
      type: AccountType.investment,
      currencyCode: 'USD',
      isArchived: false,
    ),
    Account(
      id: 'account-5',
      name: 'Office Cash',
      type: AccountType.cash,
      currencyCode: 'TRY',
      isArchived: true,
    ),
  ];
}
