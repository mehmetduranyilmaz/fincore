import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/services/credit_card_period_calculator.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_future_installments.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('includes installments later in the current month', () async {
    final useCase = GetCreditCardFutureInstallmentsUseCase(
      _TransactionRepository([
        _installment('telefon-1', 'Telefon', DateTime(2026, 8, 15), 1),
        _installment('telefon-2', 'Telefon', DateTime(2026, 9, 15), 2),
        _installment('telefon-3', 'Telefon', DateTime(2026, 10, 15), 3),
        _installment('telefon-4', 'Telefon', DateTime(2026, 11, 15), 4),
      ]),
      const _StatementRepository(),
      clock: () => DateTime(2026, 8, 8),
    );

    final result = await useCase.execute(_card);

    expect(result.map((item) => item.id), [
      'telefon-1',
      'telefon-2',
      'telefon-3',
      'telefon-4',
    ]);
    expect(result.fold<double>(0, (total, item) => total + item.amount), 4000);
  });

  test('sorts by date with the nearest installment first', () async {
    final useCase = GetCreditCardFutureInstallmentsUseCase(
      _TransactionRepository([
        _installment('telefon-4', 'Telefon', DateTime(2026, 11, 15), 4),
        _installment('ayakkabi-3', 'Ayakkabı', DateTime(2026, 10, 12), 3),
        _installment('telefon-2', 'Telefon', DateTime(2026, 9, 15), 2),
        _installment('ayakkabi-2', 'Ayakkabı', DateTime(2026, 9, 12), 2),
      ]),
      const _StatementRepository(),
      clock: () => DateTime(2026, 8, 8),
    );

    final result = await useCase.execute(_card);

    expect(result.map((item) => item.id), [
      'ayakkabi-2',
      'telefon-2',
      'ayakkabi-3',
      'telefon-4',
    ]);
  });

  test(
    'removes an installment only after a real statement assigns it',
    () async {
      final installment = _installment(
        'september-installment',
        'Telefon',
        DateTime(2026, 10, 2),
        2,
      );
      final statement = CreditCardStatement(
        id: 'september-statement',
        creditCardId: _card.id,
        statementDate: DateTime(2026, 9, 30),
        dueDate: DateTime(2026, 10, 10),
        createdAt: DateTime(2026, 9, 30),
        lines: [
          CreditCardStatementLine(
            transactionId: installment.id,
            description: installment.merchant,
            transactionDate: installment.transactionDate,
            amount: installment.amount,
            installmentNumber: installment.installmentNumber,
            installmentCount: installment.installmentCount,
          ),
        ],
      );
      final beforeCut = GetCreditCardFutureInstallmentsUseCase(
        _TransactionRepository([installment]),
        const _StatementRepository(),
        clock: () => DateTime(2026, 9, 30),
      );
      final afterCut = GetCreditCardFutureInstallmentsUseCase(
        _TransactionRepository([installment]),
        _StatementRepository([statement]),
        clock: () => DateTime(2026, 9, 30),
      );

      expect((await beforeCut.execute(_card)).single.id, installment.id);
      expect(await afterCut.execute(_card), isEmpty);
    },
  );

  test(
    'calculates the next expected cut date after the current cut passes',
    () {
      expect(
        CreditCardPeriodCalculator.upcomingStatementDate(
          referenceDate: DateTime(2026, 8, 21),
          statementDay: 20,
        ),
        DateTime(2026, 9, 20),
      );
    },
  );
}

const _card = CreditCard(
  id: 'card-1',
  bankName: 'Kuveyt Türk',
  cardName: 'Sağlam Kart',
  lastFourDigits: '1234',
  creditLimit: 10000,
  statementDay: 20,
  dueDay: 1,
  currencyCode: 'TRY',
  isArchived: false,
);

Transaction _installment(
  String id,
  String merchant,
  DateTime date,
  int number,
) => Transaction(
  id: id,
  accountId: null,
  creditCardId: _card.id,
  amount: 1000,
  transactionType: TransactionType.expense,
  categoryId: null,
  merchant: merchant,
  note: null,
  transactionDate: date,
  source: TransactionSource.manual,
  isDeleted: false,
  installmentPlanId: '$merchant-plan',
  installmentNumber: number,
  installmentCount: 4,
  installmentTotalAmount: 4000,
);

final class _StatementRepository implements CreditCardStatementRepository {
  const _StatementRepository([this.items = const []]);

  final List<CreditCardStatement> items;

  @override
  Future<void> create(CreditCardStatement statement) async {}

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
