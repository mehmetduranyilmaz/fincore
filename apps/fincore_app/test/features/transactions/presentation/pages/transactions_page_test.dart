import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:fincore_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/presentation/pages/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../transactions_test_data.dart';

void main() {
  testWidgets('renders transactions in a column on compact screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_transactionsApp(createTransactions()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transactions_column_layout')), findsOneWidget);
    expect(find.text('İşlemler'), findsOneWidget);
    expect(find.text('Test Market'), findsOneWidget);
    expect(find.text('-250,00 ₺'), findsOneWidget);
    expect(find.text('25.07.2026'), findsOneWidget);
    expect(find.text('Gider • Manuel'), findsOneWidget);
  });

  testWidgets('renders transactions in a desktop list', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_transactionsApp(createTransactions()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('transactions_desktop_list_layout')),
      findsOneWidget,
    );
    expect(find.text('Test Income'), findsOneWidget);
    expect(find.text('+5.000,00 ₺'), findsOneWidget);
    expect(find.text('Gelir • İçe Aktarma'), findsOneWidget);
  });

  testWidgets('renders the empty state when there are no transactions', (
    tester,
  ) async {
    await tester.pumpWidget(_transactionsApp(const []));
    await tester.pumpAndSettle();

    expect(find.text('Henüz işlem yok'), findsOneWidget);
  });

  testWidgets('search filters the visible transactions immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            TransactionRepositoryImpl(
              TransactionMockDataSource(
                initialTransactions: createTransactions(),
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: TransactionsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(4));

    await tester.enterText(find.byType(SearchBar), 'market');
    await tester.pumpAndSettle();

    expect(find.text('Test Market'), findsOneWidget);
    expect(find.text('Test Income'), findsNothing);
  });
}

Widget _transactionsApp(List<Transaction> transactions) {
  return ProviderScope(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(
        _TransactionRepository(transactions),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: TransactionsPage()),
    ),
  );
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.transactions);

  final List<Transaction> transactions;

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
    return transactions;
  }

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<void> update(Transaction transaction) async {}
}
