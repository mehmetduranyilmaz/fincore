import 'package:fincore_app/app/theme/app_theme.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/credit_cards_page.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../credit_cards_test_data.dart';

void main() {
  testWidgets('renders credit cards in a column on compact screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 1000);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_creditCardsApp(createCreditCards()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('credit_cards_column_layout')), findsOneWidget);
    expect(find.text('Kredi Kartları'), findsOneWidget);
    expect(find.text('Kart Ekle'), findsOneWidget);
    expect(find.text('Aylık Ödeme Takvimi'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_view_month_outlined), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    expect(find.byIcon(Icons.payment_outlined), findsNWidgets(2));
    expect(find.text('Test Bank'), findsOneWidget);
    expect(find.text('Test Card'), findsOneWidget);
    expect(find.text('****1111'), findsOneWidget);
    expect(find.text('2.500,00 ₺'), findsWidgets);
    expect(find.text('7.500,00 ₺'), findsOneWidget);
    expect(find.text('Beklenen Kesim Günü: 10'), findsOneWidget);
    expect(find.text('Son Ödeme Günü: 20'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    expect(find.byIcon(Icons.receipt_long_outlined), findsNWidgets(2));
    expect(find.byIcon(Icons.sync_alt), findsNWidgets(2));
    expect(find.byIcon(Icons.calendar_month_outlined), findsNWidgets(2));
  });

  testWidgets('renders credit cards in a grid on expanded screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_creditCardsApp(createCreditCards()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('credit_cards_grid_layout')), findsOneWidget);
    expect(find.text('Second Bank'), findsOneWidget);
    expect(find.text('****2222'), findsOneWidget);
  });

  testWidgets('renders the empty state when there are no credit cards', (
    tester,
  ) async {
    await tester.pumpWidget(_creditCardsApp(const []));
    await tester.pumpAndSettle();

    expect(find.text('Henüz kredi kartı yok'), findsOneWidget);
  });
}

Widget _creditCardsApp(List<CreditCard> creditCards) {
  return ProviderScope(
    overrides: [
      creditCardRepositoryProvider.overrideWithValue(
        _CreditCardRepository(creditCards),
      ),
      creditCardStatementRepositoryProvider.overrideWithValue(
        const _CreditCardStatementRepository(),
      ),
      transactionRepositoryProvider.overrideWithValue(
        _TransactionRepository(_transactions()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: CreditCardsPage()),
    ),
  );
}

final class _CreditCardStatementRepository
    implements CreditCardStatementRepository {
  const _CreditCardStatementRepository();

  @override
  Future<void> create(CreditCardStatement statement) async {}

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async => const [];
}

List<Transaction> _transactions() {
  return [
    _transaction(
      id: 'card-1-expense',
      creditCardId: 'credit-card-1',
      amount: 3000,
      type: TransactionType.expense,
    ),
    _transaction(
      id: 'card-1-payment',
      creditCardId: 'credit-card-1',
      amount: 500,
      type: TransactionType.income,
    ),
    _transaction(
      id: 'card-2-expense',
      creditCardId: 'credit-card-2',
      amount: 6000,
      type: TransactionType.expense,
    ),
    _transaction(
      id: 'card-2-payment',
      creditCardId: 'credit-card-2',
      amount: 1000,
      type: TransactionType.income,
    ),
  ];
}

Transaction _transaction({
  required String id,
  required String creditCardId,
  required double amount,
  required TransactionType type,
}) {
  return Transaction(
    id: id,
    accountId: null,
    creditCardId: creditCardId,
    amount: amount,
    transactionType: type,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: DateTime(2026, 7, 25),
    source: TransactionSource.import,
    isDeleted: false,
  );
}

final class _CreditCardRepository implements CreditCardRepository {
  const _CreditCardRepository(this.creditCards);

  final List<CreditCard> creditCards;

  @override
  Future<List<CreditCard>> getCreditCards() async => creditCards;
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
              filter.creditCardId == null ||
              transaction.creditCardId == filter.creditCardId,
        )
        .toList(growable: false);
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
