import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_activity_summary.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:fincore_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'uses only manual statements and leaves unassigned movements in period',
    () async {
      final repository = TransactionRepositoryImpl(
        TransactionMockDataSource(
          initialTransactions: [
            _expense('statement', DateTime(2026, 7, 5), 100),
            _expense('current', DateTime(2026, 8, 6), 40),
            _customerCardPayment(
              'customer-payment',
              DateTime(2026, 8, 6),
              22750,
            ),
            _cardDebtPayment(
              'card-payment',
              DateTime(2026, 8, 6),
              500,
              statementId: 'other-statement',
            ),
            _expense('future', DateTime(2026, 9, 6), 25, installment: true),
          ],
        ),
      );
      final useCase = GetCreditCardActivitySummaryUseCase(
        repository,
        statementRepository: _StatementRepository([
          CreditCardStatement(
            id: 'statement-1',
            creditCardId: _card.id,
            statementDate: DateTime(2026, 8, 5),
            dueDate: DateTime(2026, 8, 15),
            createdAt: DateTime(2026, 8, 5),
            lines: [
              CreditCardStatementLine(
                transactionId: 'statement',
                description: 'statement',
                transactionDate: DateTime(2026, 7, 5),
                amount: 100,
              ),
            ],
          ),
        ]),
        clock: () => DateTime(2026, 8, 7),
      );

      final summary = await useCase.execute(_card);

      expect(summary.statementAmount, 100);
      expect(summary.currentPeriodAmount, 22790);
      expect(summary.futureInstallmentAmount, 25);
    },
  );

  test('shows the remaining latest statement amount after payments', () async {
    final repository = TransactionRepositoryImpl(
      TransactionMockDataSource(
        initialTransactions: [
          _expense('statement', DateTime(2026, 8, 5), 60004.21),
          _cardDebtPayment(
            'partial-payment',
            DateTime(2026, 9, 1),
            30004.21,
            statementId: 'statement-1',
          ),
        ],
      ),
    );
    final useCase = GetCreditCardActivitySummaryUseCase(
      repository,
      statementRepository: _StatementRepository([
        CreditCardStatement(
          id: 'statement-1',
          creditCardId: _card.id,
          statementDate: DateTime(2026, 8, 30),
          dueDate: DateTime(2026, 9, 10),
          createdAt: DateTime(2026, 8, 30),
          lines: [
            CreditCardStatementLine(
              transactionId: 'statement',
              description: 'statement',
              transactionDate: DateTime(2026, 8, 5),
              amount: 60004.21,
            ),
          ],
        ),
      ]),
      clock: () => DateTime(2026, 9, 1),
    );

    final summary = await useCase.execute(_card);

    expect(summary.statementAmount, closeTo(30000, 0.001));
  });

  test(
    'shows zero when an unlinked payment fully covers the oldest statement',
    () async {
      final repository = TransactionRepositoryImpl(
        TransactionMockDataSource(
          initialTransactions: [
            _expense('statement', DateTime(2026, 8, 5), 30004.21),
            _cardDebtPayment('full-payment', DateTime(2026, 9, 1), 30004.21),
          ],
        ),
      );
      final useCase = GetCreditCardActivitySummaryUseCase(
        repository,
        statementRepository: _StatementRepository([
          CreditCardStatement(
            id: 'statement-1',
            creditCardId: _card.id,
            statementDate: DateTime(2026, 8, 30),
            dueDate: DateTime(2026, 9, 10),
            createdAt: DateTime(2026, 8, 30),
            lines: [
              CreditCardStatementLine(
                transactionId: 'statement',
                description: 'statement',
                transactionDate: DateTime(2026, 8, 5),
                amount: 30004.21,
              ),
            ],
          ),
        ]),
        clock: () => DateTime(2026, 9, 1),
      );

      final summary = await useCase.execute(_card);

      expect(summary.statementAmount, 0);
    },
  );

  test(
    'future total includes later installments in the current month',
    () async {
      final repository = TransactionRepositoryImpl(
        TransactionMockDataSource(
          initialTransactions: [
            _expense('august', DateTime(2026, 8, 15), 1000, installment: true),
            _expense(
              'september',
              DateTime(2026, 9, 15),
              1000,
              installment: true,
            ),
            _expense(
              'october',
              DateTime(2026, 10, 15),
              1000,
              installment: true,
            ),
            _expense(
              'november',
              DateTime(2026, 11, 15),
              1000,
              installment: true,
            ),
          ],
        ),
      );
      final useCase = GetCreditCardActivitySummaryUseCase(
        repository,
        statementRepository: const _StatementRepository([]),
        clock: () => DateTime(2026, 8, 8),
      );

      final summary = await useCase.execute(_card.copyWith(statementDay: 20));

      expect(summary.futureInstallmentAmount, 4000);
    },
  );
}

Transaction _customerCardPayment(String id, DateTime date, double amount) {
  return Transaction(
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
}

Transaction _cardDebtPayment(
  String id,
  DateTime date,
  double amount, {
  String? statementId,
}) {
  return Transaction(
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
    paymentGroupId: 'card-payment-group',
    creditCardStatementId: statementId,
  );
}

final class _StatementRepository implements CreditCardStatementRepository {
  const _StatementRepository(this.items);

  final List<CreditCardStatement> items;

  @override
  Future<void> create(CreditCardStatement statement) async {}

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async => items;
}

const _card = CreditCard(
  id: 'card-1',
  bankName: 'Test',
  cardName: 'Kart',
  lastFourDigits: '1234',
  creditLimit: 1000,
  statementDay: 5,
  dueDay: 15,
  currencyCode: 'TRY',
  isArchived: false,
);

Transaction _expense(
  String id,
  DateTime date,
  double amount, {
  bool installment = false,
}) {
  return Transaction(
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
    installmentPlanId: installment ? 'plan-1' : null,
    installmentNumber: installment ? 2 : null,
    installmentCount: installment ? 2 : null,
    installmentTotalAmount: installment ? 50 : null,
  );
}
