import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/presentation/pages/edit_transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders editable fields with immutable type and source', (
    tester,
  ) async {
    final transaction = _transaction();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(
            _TransactionRepository(transaction),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: EditTransactionPage(transactionId: transaction.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('İşlemi Düzenle'), findsOneWidget);
    expect(find.text('Gider'), findsOneWidget);
    expect(find.text('Manuel'), findsOneWidget);
    expect(find.text('Hesap veya Kredi Kartı'), findsOneWidget);
    expect(find.text('Tutar'), findsOneWidget);
    expect(find.text('Açıklama'), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Değişiklikleri Kaydet'), findsOneWidget);
  });
}

Transaction _transaction() {
  return Transaction(
    id: 'transaction-1',
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
