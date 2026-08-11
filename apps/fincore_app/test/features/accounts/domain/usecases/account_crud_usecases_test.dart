import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/entities/create_account_input.dart';
import 'package:fincore_app/features/accounts/domain/entities/update_account_input.dart';
import 'package:fincore_app/features/accounts/domain/errors/account_operation_exception.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_command_repository.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_usage_repository.dart';
import 'package:fincore_app/features/accounts/domain/usecases/calculate_account_balance.dart';
import 'package:fincore_app/features/accounts/domain/usecases/create_account.dart';
import 'package:fincore_app/features/accounts/domain/usecases/delete_account.dart';
import 'package:fincore_app/features/accounts/domain/usecases/update_account.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a persistent account with its opening balance', () async {
    final accounts = _AccountRepository();
    final created =
        await CreateAccountUseCase(
          accounts,
          accounts,
          idGenerator: () => 'account-new',
        ).execute(
          const CreateAccountInput(
            name: '  İş Bankası ',
            type: AccountType.checking,
            currencyCode: 'TRY',
            openingBalance: 1250.50,
            bankId: 'isbank',
            iban: 'TR33 0006 1005 1978 6457 8413 26',
          ),
        );

    expect(created.name, 'İş Bankası');
    expect(created.openingBalance, 1250.50);
    expect(created.bankId, 'isbank');
    expect(created.iban, 'TR330006100519786457841326');
    expect(accounts.items, [created]);
  });

  test('account names are unique with Turkish casing', () {
    final accounts = _AccountRepository([_account]);

    expect(
      () => CreateAccountUseCase(accounts, accounts).execute(
        const CreateAccountInput(
          name: '  İŞ BANKASI ',
          type: AccountType.checking,
          currencyCode: 'TRY',
          openingBalance: 0,
          bankId: 'isbank',
        ),
      ),
      throwsA(isA<AccountOperationException>()),
    );
  });

  test('movement account keeps structural fields immutable', () {
    final accounts = _AccountRepository([_account]);
    final useCase = UpdateAccountUseCase(
      accounts,
      accounts,
      _TransactionRepository([_expense]),
    );

    expect(
      () => useCase.execute(
        const UpdateAccountInput(
          accountId: 'account-1',
          name: 'İş Bankası Yeni',
          type: AccountType.savings,
          currencyCode: 'TRY',
          openingBalance: 100,
          bankId: 'isbank',
          iban: 'TR330006100519786457841326',
        ),
      ),
      throwsA(isA<AccountOperationException>()),
    );
  });

  test('rejects a duplicate IBAN even when formatted differently', () {
    final accounts = _AccountRepository([_account]);

    expect(
      () => CreateAccountUseCase(accounts, accounts).execute(
        const CreateAccountInput(
          name: 'Başka Hesap',
          type: AccountType.checking,
          currencyCode: 'TRY',
          openingBalance: 0,
          bankId: 'kuveyt_turk',
          iban: 'TR33 0006 1005 1978 6457 8413 26',
        ),
      ),
      throwsA(isA<AccountOperationException>()),
    );
  });

  test('rejects invalid Turkish IBAN values', () {
    final accounts = _AccountRepository();

    expect(
      () => CreateAccountUseCase(accounts, accounts).execute(
        const CreateAccountInput(
          name: 'Kuveyt Türk',
          type: AccountType.checking,
          currencyCode: 'TRY',
          openingBalance: 0,
          bankId: 'kuveyt_turk',
          iban: 'TR00 0000 0000 0000 0000 0000 00',
        ),
      ),
      throwsA(isA<AccountOperationException>()),
    );
  });

  test('opening balance participates in current balance', () async {
    final accounts = _AccountRepository([_account]);
    final balance = await CalculateAccountBalanceUseCase(
      _TransactionRepository([_expense]),
      accountRepository: accounts,
    ).execute(_account.id);

    expect(balance.currentBalance, 75);
  });

  test('archives a zero-balance account', () async {
    final account = _account.copyWith(openingBalance: 0);
    final accounts = _AccountRepository([account]);
    final calculator = CalculateAccountBalanceUseCase(
      const _TransactionRepository([]),
      accountRepository: accounts,
    );

    await DeleteAccountUseCase(
      accounts,
      calculator,
      const _AccountUsageRepository(false),
    ).execute(account.id);

    expect(accounts.items.single.isArchived, isTrue);
  });

  test('does not archive an account that has movement history', () async {
    final account = _account.copyWith(openingBalance: 0);
    final accounts = _AccountRepository([account]);
    final calculator = CalculateAccountBalanceUseCase(
      const _TransactionRepository([]),
      accountRepository: accounts,
    );

    await expectLater(
      DeleteAccountUseCase(
        accounts,
        calculator,
        const _AccountUsageRepository(true),
      ).execute(account.id),
      throwsA(isA<AccountOperationException>()),
    );
    expect(accounts.items.single.isArchived, isFalse);
  });
}

final class _AccountUsageRepository implements AccountUsageRepository {
  const _AccountUsageRepository(this.hasMovements);

  final bool hasMovements;

  @override
  Future<bool> hasUsage(String accountId) async => hasMovements;
}

const _account = Account(
  id: 'account-1',
  name: 'İş Bankası',
  type: AccountType.checking,
  currencyCode: 'TRY',
  isArchived: false,
  openingBalance: 100,
  bankId: 'isbank',
  iban: 'TR330006100519786457841326',
);

final _expense = Transaction(
  id: 'expense-1',
  accountId: 'account-1',
  creditCardId: null,
  amount: 25,
  transactionType: TransactionType.expense,
  categoryId: null,
  merchant: 'Gider',
  note: null,
  transactionDate: DateTime(2026, 8, 7),
  source: TransactionSource.manual,
  isDeleted: false,
);

final class _AccountRepository
    implements AccountRepository, AccountCommandRepository {
  _AccountRepository([List<Account> seed = const []]) : items = [...seed];
  final List<Account> items;

  @override
  Future<List<Account>> getAccounts() async =>
      items.where((account) => !account.isArchived).toList();

  @override
  Future<Account?> getById(String accountId) async {
    for (final account in items) {
      if (account.id == accountId && !account.isArchived) return account;
    }
    return null;
  }

  @override
  Future<void> create(Account account) async => items.add(account);

  @override
  Future<void> update(Account account) async {
    final index = items.indexWhere((item) => item.id == account.id);
    items[index] = account;
  }

  @override
  Future<void> archive(String accountId) async {
    final index = items.indexWhere((item) => item.id == accountId);
    items[index] = items[index].copyWith(isArchived: true);
  }
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.items);
  final List<Transaction> items;

  @override
  Future<void> create(Transaction transaction) async {}
  @override
  Future<void> createMany(List<Transaction> transactions) async {}
  @override
  Future<Transaction?> getById(String transactionId) async => null;
  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async =>
      items
          .where(
            (item) =>
                filter.accountId == null || item.accountId == filter.accountId,
          )
          .toList();
  @override
  Future<void> update(Transaction transaction) async {}
}
