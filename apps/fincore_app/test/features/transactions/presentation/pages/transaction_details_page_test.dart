import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/presentation/pages/transaction_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows transaction fields and edit for an editable transaction', (
    tester,
  ) async {
    await tester.pumpWidget(_detailsApp(_manualExpense()));
    await tester.pumpAndSettle();

    expect(find.text('İşlem Detayları'), findsOneWidget);
    expect(find.text('250,00 ₺'), findsOneWidget);
    expect(find.text('Market'), findsNWidgets(2));
    expect(find.text('25.07.2026'), findsOneWidget);
    expect(find.text('Ana Hesap'), findsOneWidget);
    expect(find.text('Gider'), findsOneWidget);
    expect(find.text('Manuel'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('does not show edit for a transfer', (tester) async {
    await tester.pumpWidget(_detailsApp(_transfer()));
    await tester.pumpAndSettle();

    expect(find.text('Transfer'), findsWidgets);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });
}

Widget _detailsApp(Transaction transaction) {
  return ProviderScope(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(
        _TransactionRepository(transaction),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: TransactionDetailsPage(transactionId: transaction.id),
    ),
  );
}

Transaction _manualExpense() {
  return Transaction(
    id: 'manual-expense',
    accountId: 'account-1',
    creditCardId: null,
    amount: 250,
    transactionType: TransactionType.expense,
    categoryId: 'category-market',
    merchant: 'Market',
    note: null,
    transactionDate: DateTime(2026, 7, 25),
    source: TransactionSource.manual,
    isDeleted: false,
  );
}

Transaction _transfer() {
  return Transaction(
    id: 'transfer',
    accountId: 'account-1',
    creditCardId: null,
    amount: -100,
    transactionType: TransactionType.transfer,
    categoryId: null,
    merchant: 'Transfer',
    note: null,
    transactionDate: DateTime(2026, 7, 25),
    source: TransactionSource.manual,
    isDeleted: false,
    transferGroupId: 'group-1',
  );
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.transaction);

  final Transaction transaction;

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<Transaction?> getById(String transactionId) async => transaction;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return [transaction];
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
