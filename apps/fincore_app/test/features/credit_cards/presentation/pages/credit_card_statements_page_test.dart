import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/credit_card_statements_page.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows remaining statement debt and payment action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          creditCardRepositoryProvider.overrideWithValue(
            const _CreditCardRepository(),
          ),
          creditCardStatementRepositoryProvider.overrideWithValue(
            _StatementRepository(_statement),
          ),
          transactionRepositoryProvider.overrideWithValue(
            _TransactionRepository(_statementPayment),
          ),
        ],
        child: const MaterialApp(
          home: CreditCardStatementsPage(creditCardId: 'card-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('300,00 ₺'), findsOneWidget);
    expect(find.text('Kalan: 200,00 ₺'), findsOneWidget);
    expect(find.byKey(const Key('pay_statement_statement-1')), findsOneWidget);
    expect(find.text('Öde'), findsOneWidget);
  });
}

const _card = CreditCard(
  id: 'card-1',
  bankName: 'Test Bank',
  cardName: 'Test Kart',
  lastFourDigits: '1234',
  creditLimit: 10000,
  statementDay: 5,
  dueDay: 20,
  currencyCode: 'TRY',
  isArchived: false,
);

final _statement = CreditCardStatement(
  id: 'statement-1',
  creditCardId: _card.id,
  statementDate: DateTime(2026, 8, 5),
  dueDate: DateTime(2026, 8, 20),
  lines: [
    CreditCardStatementLine(
      transactionId: 'expense-1',
      description: 'Harcama',
      transactionDate: DateTime(2026, 8, 1),
      amount: 300,
    ),
  ],
  createdAt: DateTime(2026, 8, 5),
);

final _statementPayment = Transaction(
  id: 'payment-1',
  accountId: null,
  creditCardId: _card.id,
  amount: 100,
  transactionType: TransactionType.income,
  categoryId: null,
  merchant: 'Ekstre ödemesi',
  note: null,
  transactionDate: DateTime(2026, 8, 10),
  source: TransactionSource.manual,
  isDeleted: false,
  paymentGroupId: 'payment-group',
  creditCardStatementId: _statement.id,
);

final class _CreditCardRepository implements CreditCardRepository {
  const _CreditCardRepository();

  @override
  Future<List<CreditCard>> getCreditCards() async => const [_card];
}

final class _StatementRepository implements CreditCardStatementRepository {
  const _StatementRepository(this.statement);

  final CreditCardStatement statement;

  @override
  Future<void> create(CreditCardStatement statement) async {}

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async => [statement];
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.transaction);

  final Transaction transaction;

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async => [
    transaction,
  ];

  @override
  Future<void> update(Transaction transaction) async {}
}
