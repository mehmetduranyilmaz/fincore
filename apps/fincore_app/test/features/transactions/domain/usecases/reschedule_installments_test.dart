import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/reschedule_installments.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _TransactionRepository repository;
  late RescheduleInstallmentsUseCase useCase;

  setUp(() {
    repository = _TransactionRepository([
      _installment(1, DateTime(2026, 9, 15)),
      _installment(2, DateTime(2026, 10, 15)),
      _installment(3, DateTime(2026, 11, 15)),
      _installment(4, DateTime(2026, 12, 15)),
    ]);
    useCase = RescheduleInstallmentsUseCase(
      repository,
      statementRepository: _StatementRepository([
        CreditCardStatement(
          id: 'statement-october',
          creditCardId: 'card-1',
          statementDate: DateTime(2026, 10, 20),
          dueDate: DateTime(2026, 10, 30),
          lines: [
            CreditCardStatementLine(
              transactionId: 'tx-2',
              description: 'Laptop',
              transactionDate: DateTime(2026, 10, 15),
              amount: 250,
            ),
          ],
          createdAt: DateTime(2026, 10, 20),
        ),
      ]),
      clock: () => DateTime(2026, 10, 10, 14),
    );
  });

  test('only future installments outside cut statements can move', () async {
    final plan = await useCase.getPlan('plan-1');

    expect(plan.map((item) => item.id), ['tx-1', 'tx-2', 'tx-3', 'tx-4']);
    expect(await useCase.reschedulableIds(plan), {'tx-3', 'tx-4'});
  });

  test('moves future installment dates and keeps other fields', () async {
    final changed = await useCase.execute(
      RescheduleInstallmentsInput(
        installmentPlanId: 'plan-1',
        datesByTransactionId: {
          'tx-3': DateTime(2026, 12, 1),
          'tx-4': DateTime(2027, 1, 5),
        },
      ),
    );

    expect(changed.map((item) => item.id), ['tx-3', 'tx-4']);
    final third = repository.byId('tx-3');
    expect(third.transactionDate, DateTime(2026, 12, 1));
    expect(third.amount, 250);
    expect(third.installmentNumber, 3);
    expect(third.installmentPlanId, 'plan-1');
    expect(repository.byId('tx-4').transactionDate, DateTime(2027, 1, 5));
    expect(repository.byId('tx-1').transactionDate, DateTime(2026, 9, 15));
  });

  test('moves an installment earlier, down to the day after the last cut '
      'statement', () async {
    final plan = await useCase.getPlan('plan-1');
    expect(await useCase.earliestDate(plan), DateTime(2026, 10, 21));

    await useCase.execute(
      RescheduleInstallmentsInput(
        installmentPlanId: 'plan-1',
        datesByTransactionId: {'tx-3': DateTime(2026, 10, 21)},
      ),
    );

    expect(repository.byId('tx-3').transactionDate, DateTime(2026, 10, 21));
  });

  test('rejects locked installments, past dates and unordered dates', () async {
    Future<void> run(Map<String, DateTime> dates) => useCase.execute(
      RescheduleInstallmentsInput(
        installmentPlanId: 'plan-1',
        datesByTransactionId: dates,
      ),
    );

    await expectLater(
      run({'tx-2': DateTime(2026, 11, 1)}),
      throwsArgumentError,
    );
    await expectLater(
      run({'tx-3': DateTime(2026, 10, 10)}),
      throwsArgumentError,
    );
    await expectLater(run({'tx-3': DateTime(2027, 1, 1)}), throwsArgumentError);
    expect(repository.updates, isEmpty);
  });
}

Transaction _installment(int number, DateTime date) {
  return Transaction(
    id: 'tx-$number',
    accountId: null,
    creditCardId: 'card-1',
    amount: 250,
    transactionType: TransactionType.expense,
    categoryId: null,
    merchant: 'Laptop',
    note: null,
    transactionDate: date,
    source: TransactionSource.manual,
    isDeleted: false,
    installmentPlanId: 'plan-1',
    installmentNumber: number,
    installmentCount: 4,
    installmentTotalAmount: 1000,
  );
}

final class _TransactionRepository implements TransactionRepository {
  _TransactionRepository(List<Transaction> transactions)
    : _transactions = [...transactions];

  final List<Transaction> _transactions;
  final List<Transaction> updates = [];

  Transaction byId(String id) =>
      _transactions.singleWhere((item) => item.id == id);

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<Transaction?> getById(String transactionId) async =>
      _transactions.where((item) => item.id == transactionId).firstOrNull;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async =>
      // Reverse to prove the use case sorts by installment number.
      _transactions.reversed.toList();

  @override
  Future<void> update(Transaction transaction) async {
    updates.add(transaction);
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    _transactions[index] = transaction;
  }
}

final class _StatementRepository implements CreditCardStatementRepository {
  const _StatementRepository(this.items);

  final List<CreditCardStatement> items;

  @override
  Future<void> create(CreditCardStatement statement) async {}

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async => items.where((item) => item.creditCardId == creditCardId).toList();
}
