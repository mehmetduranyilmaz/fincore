import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/presentation/pages/create_transfer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the transfer form and validates required fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(
            const _AccountRepository(),
          ),
          transactionRepositoryProvider.overrideWithValue(
            _TransactionRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CreateTransferPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transfer Oluştur'), findsOneWidget);
    expect(find.text('Gönderen Hesap'), findsOneWidget);
    expect(find.text('Alıcı Hesap'), findsOneWidget);
    expect(find.text('Tutar'), findsOneWidget);
    expect(find.text('Açıklama'), findsOneWidget);

    await tester.tap(find.text('Transferi Kaydet'));
    await tester.pump();

    expect(find.text('Bu alan zorunludur.'), findsNWidgets(4));
  });
}

final class _AccountRepository implements AccountRepository {
  const _AccountRepository();

  @override
  Future<List<Account>> getAccounts() async {
    return const [
      Account(
        id: 'account-1',
        name: 'Source',
        type: AccountType.checking,
        currencyCode: 'TRY',
        isArchived: false,
      ),
      Account(
        id: 'account-2',
        name: 'Destination',
        type: AccountType.savings,
        currencyCode: 'TRY',
        isArchived: false,
      ),
    ];
  }
}

final class _TransactionRepository implements TransactionRepository {
  final List<Transaction> transactions = [];

  @override
  Future<void> create(Transaction transaction) async {
    transactions.insert(0, transaction);
  }

  @override
  Future<void> createMany(List<Transaction> transactions) async {
    this.transactions.insertAll(0, transactions);
  }

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return List.unmodifiable(transactions);
  }

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<void> update(Transaction transaction) async {}
}
