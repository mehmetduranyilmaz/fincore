import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/presentation/pages/accounts_page.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../accounts_test_data.dart';

void main() {
  testWidgets('renders accounts in a list on compact screens', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_accountsApp(createAccounts()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('accounts_list_layout')), findsOneWidget);
    expect(find.text('Hesaplar'), findsOneWidget);
    expect(find.text('Test Checking'), findsOneWidget);
    expect(find.text('Vadesiz Hesap'), findsOneWidget);
    expect(find.text('Kuveyt Türk'), findsOneWidget);
    expect(find.text('TR33 0006 1005 1978 6457 8413 26'), findsOneWidget);
    expect(find.bySemanticsLabel('Kuveyt Türk banka ikonu'), findsOneWidget);
    expect(find.text('1.500,00 ₺'), findsOneWidget);
    expect(find.text('Toplam Gelir: 2.000,00 ₺'), findsOneWidget);
    expect(find.text('Toplam Gider: 500,00 ₺'), findsOneWidget);
    expect(find.byKey(const Key('create_account_button')), findsOneWidget);
    expect(find.byKey(const Key('edit_account_account-1')), findsOneWidget);
    expect(find.byKey(const Key('delete_account_account-1')), findsOneWidget);
    semanticsHandle.dispose();
  });

  testWidgets('renders accounts in a grid on expanded screens', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_accountsApp(createAccounts()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('accounts_grid_layout')), findsOneWidget);
    expect(find.text('Test Savings'), findsOneWidget);
    expect(find.text('750,00 \$'), findsOneWidget);
  });

  testWidgets('renders the empty state when there are no accounts', (
    tester,
  ) async {
    await tester.pumpWidget(_accountsApp(const []));
    await tester.pumpAndSettle();

    expect(find.text('Henüz hesap yok'), findsOneWidget);
  });
}

Widget _accountsApp(List<Account> accounts) {
  return ProviderScope(
    overrides: [
      accountRepositoryProvider.overrideWithValue(_AccountRepository(accounts)),
      transactionRepositoryProvider.overrideWithValue(
        _TransactionRepository(_transactions()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: AccountsPage()),
    ),
  );
}

List<Transaction> _transactions() {
  return [
    _transaction(
      id: 'account-1-income',
      accountId: 'account-1',
      amount: 2000,
      type: TransactionType.income,
    ),
    _transaction(
      id: 'account-1-expense',
      accountId: 'account-1',
      amount: 500,
      type: TransactionType.expense,
    ),
    _transaction(
      id: 'account-2-income',
      accountId: 'account-2',
      amount: 1000,
      type: TransactionType.income,
    ),
    _transaction(
      id: 'account-2-expense',
      accountId: 'account-2',
      amount: 250,
      type: TransactionType.expense,
    ),
  ];
}

Transaction _transaction({
  required String id,
  required String accountId,
  required double amount,
  required TransactionType type,
}) {
  return Transaction(
    id: id,
    accountId: accountId,
    creditCardId: null,
    amount: amount,
    transactionType: type,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: DateTime(2026, 7, 25),
    source: TransactionSource.manual,
    isDeleted: false,
  );
}

final class _AccountRepository implements AccountRepository {
  const _AccountRepository(this.accounts);

  final List<Account> accounts;

  @override
  Future<List<Account>> getAccounts() async => accounts;
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.transactions);

  final List<Transaction> transactions;

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return transactions
        .where(
          (transaction) =>
              filter.accountId == null ||
              transaction.accountId == filter.accountId,
        )
        .toList(growable: false);
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
