import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_command_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/create_credit_card_statement_page.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'suggests older movements but leaves cutoff-day items unchecked',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(600, 1000);
      addTearDown(tester.view.reset);
      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            creditCardCommandRepositoryProvider.overrideWithValue(
              const _CardRepository(),
            ),
            creditCardStatementRepositoryProvider.overrideWithValue(
              _StatementRepository(),
            ),
            transactionRepositoryProvider.overrideWithValue(
              _TransactionRepository([
                _expense(
                  'older',
                  dateOnly.subtract(const Duration(days: 1)),
                  100,
                ),
                _expense('cutoff', dateOnly.add(const Duration(hours: 9)), 50),
                _payment('payment', dateOnly, 25),
              ]),
            ),
          ],
          child: const MaterialApp(
            home: CreateCreditCardStatementPage(creditCardId: 'card-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('statement_candidate_list')), findsOneWidget);
      expect(find.text('Seçilen hareket: 1/2'), findsOneWidget);
      expect(find.textContaining('Kesim günü'), findsWidgets);
      expect(find.text('payment'), findsNothing);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('statement_line_older')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('statement_line_cutoff')),
            )
            .value,
        isFalse,
      );

      await tester.tap(find.byKey(const Key('statement_line_cutoff')));
      await tester.pump();

      expect(find.text('Seçilen hareket: 2/2'), findsOneWidget);
      expect(find.text('150,00 ₺'), findsOneWidget);
    },
  );
}

const _card = CreditCard(
  id: 'card-1',
  bankName: 'Kuveyt Türk',
  cardName: 'Sağlam Kart',
  lastFourDigits: '1234',
  creditLimit: 10000,
  statementDay: 5,
  dueDay: 15,
  currencyCode: 'TRY',
  isArchived: false,
);

Transaction _expense(String id, DateTime date, double amount) => Transaction(
  id: id,
  accountId: null,
  creditCardId: _card.id,
  amount: amount,
  transactionType: TransactionType.expense,
  categoryId: null,
  merchant: id,
  note: null,
  transactionDate: date,
  source: TransactionSource.manual,
  isDeleted: false,
);

Transaction _payment(String id, DateTime date, double amount) => Transaction(
  id: id,
  accountId: null,
  creditCardId: _card.id,
  amount: amount,
  transactionType: TransactionType.income,
  categoryId: null,
  merchant: id,
  note: null,
  transactionDate: date,
  source: TransactionSource.manual,
  isDeleted: false,
  paymentGroupId: 'payment-group',
);

final class _CardRepository implements CreditCardCommandRepository {
  const _CardRepository();

  @override
  Future<CreditCard?> getById(String creditCardId) async => _card;

  @override
  Future<void> create(CreditCard creditCard) async {}

  @override
  Future<void> delete(String creditCardId) async {}

  @override
  Future<void> update(CreditCard creditCard) async {}
}

final class _StatementRepository implements CreditCardStatementRepository {
  final List<CreditCardStatement> items = [];

  @override
  Future<void> create(CreditCardStatement statement) async =>
      items.add(statement);

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async => items;
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
      items;

  @override
  Future<void> update(Transaction transaction) async {}
}
