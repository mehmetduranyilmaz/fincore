import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/errors/credit_card_operation_exception.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_command_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/create_credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_statement_candidates.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a statement only from explicitly selected movements', () async {
    final statements = _StatementRepository();
    final transactions = _TransactionRepository([
      _expense('older', DateTime(2026, 8, 4), 100),
      _expense('cutoff-a', DateTime(2026, 8, 5, 9), 50),
      _expense('cutoff-b', DateTime(2026, 8, 5, 18), 75),
      _payment('payment', DateTime(2026, 8, 5), 20),
    ]);
    final useCase = CreateCreditCardStatementUseCase(
      statements,
      _CardRepository(),
      transactions,
      clock: () => DateTime(2026, 8, 7),
      idGenerator: () => 'statement-1',
    );

    final statement = await useCase.execute(
      CreateCreditCardStatementInput(
        creditCardId: _card.id,
        statementDate: DateTime(2026, 8, 5),
        dueDate: DateTime(2026, 8, 15),
        transactionIds: const {'older', 'cutoff-b'},
      ),
    );

    expect(statement.lines.map((line) => line.transactionId), [
      'older',
      'cutoff-b',
    ]);
    expect(statement.totalAmount, 175);
    expect(statements.items, [statement]);
  });

  test(
    'candidate query excludes card debt payments and assigned lines',
    () async {
      final statements = _StatementRepository([
        CreditCardStatement(
          id: 'statement-old',
          creditCardId: _card.id,
          statementDate: DateTime(2026, 8, 4),
          dueDate: DateTime(2026, 8, 14),
          createdAt: DateTime(2026, 8, 4),
          lines: [
            CreditCardStatementLine(
              transactionId: 'assigned',
              description: 'assigned',
              transactionDate: DateTime(2026, 8, 3),
              amount: 10,
            ),
          ],
        ),
      ]);
      final useCase = GetCreditCardStatementCandidatesUseCase(
        statements,
        _TransactionRepository([
          _expense('assigned', DateTime(2026, 8, 3), 10),
          _expense('available', DateTime(2026, 8, 5), 20),
          _customerCardPayment('customer-payment', DateTime(2026, 8, 5), 22750),
          _payment('payment', DateTime(2026, 8, 5), 15),
          _expense('future', DateTime(2026, 8, 6), 30),
        ]),
      );

      final result = await useCase.execute(
        creditCardId: _card.id,
        statementDate: DateTime(2026, 8, 5),
      );

      expect(result.map((item) => item.id).toSet(), {
        'available',
        'customer-payment',
      });
    },
  );

  test('rejects an unselected or already assigned movement', () async {
    final statements = _StatementRepository();
    final useCase = CreateCreditCardStatementUseCase(
      statements,
      _CardRepository(),
      _TransactionRepository([_expense('available', DateTime(2026, 8, 5), 20)]),
      clock: () => DateTime(2026, 8, 7),
    );

    expect(
      () => useCase.execute(
        CreateCreditCardStatementInput(
          creditCardId: _card.id,
          statementDate: DateTime(2026, 8, 5),
          dueDate: DateTime(2026, 8, 15),
          transactionIds: const {'unknown'},
        ),
      ),
      throwsA(isA<CreditCardOperationException>()),
    );
  });
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

Transaction _customerCardPayment(String id, DateTime date, double amount) =>
    Transaction(
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
      paymentGroupId: 'customer-payment-group',
      customerId: 'customer-1',
      customerBalanceDelta: amount,
    );

final class _StatementRepository implements CreditCardStatementRepository {
  _StatementRepository([List<CreditCardStatement> seed = const []])
    : items = [...seed];

  final List<CreditCardStatement> items;

  @override
  Future<void> create(CreditCardStatement statement) async =>
      items.add(statement);

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async => items.where((item) => item.creditCardId == creditCardId).toList();
}

final class _CardRepository implements CreditCardCommandRepository {
  @override
  Future<CreditCard?> getById(String creditCardId) async =>
      creditCardId == _card.id ? _card : null;

  @override
  Future<void> create(CreditCard creditCard) async {}

  @override
  Future<void> delete(String creditCardId) async {}

  @override
  Future<void> update(CreditCard creditCard) async {}
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
