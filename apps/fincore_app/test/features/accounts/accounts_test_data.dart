import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';

List<Account> createAccounts() {
  return const [
    Account(
      id: 'account-1',
      name: 'Test Checking',
      type: AccountType.checking,
      currencyCode: 'TRY',
      isArchived: false,
      bankId: 'kuveyt_turk',
      iban: 'TR330006100519786457841326',
    ),
    Account(
      id: 'account-2',
      name: 'Test Savings',
      type: AccountType.savings,
      currencyCode: 'USD',
      isArchived: false,
      bankId: 'isbank',
    ),
  ];
}
