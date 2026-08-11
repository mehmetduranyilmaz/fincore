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
  test('uses the upcoming statement cutoff, not the calendar month', () async {
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
      'telefon-2',
      'telefon-3',
      'telefon-4',
    ]);
    expect(result.fold<double>(0, (total, item) => total + item.amount), 3000);
  });

  test('sorts by Turkish description then installment sequence', () async {
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
      'ayakkabi-3',
      'telefon-2',
      'telefon-4',
    ]);
  });

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
  const _StatementRepository();

  @override
  Future<void> create(CreditCardStatement statement) async {}

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async => const [];
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
