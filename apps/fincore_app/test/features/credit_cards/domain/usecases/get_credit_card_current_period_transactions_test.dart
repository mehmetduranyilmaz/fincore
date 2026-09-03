import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_current_period_transactions.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'includes customer card payments and excludes card debt payments',
    () async {
      final useCase = GetCreditCardCurrentPeriodTransactionsUseCase(
        _TransactionRepository([_customerCardPayment(), _cardDebtPayment()]),
        const _StatementRepository(),
        clock: () => DateTime(2026, 8, 13),
      );

      final result = await useCase.execute('card-1');

      expect(result.map((item) => item.id), ['customer-payment']);
    },
  );

  test(
    'moves an unassigned installment into period when its date arrives',
    () async {
      final installment = Transaction(
        id: 'september-installment',
        accountId: null,
        creditCardId: 'card-1',
        amount: 1250,
        transactionType: TransactionType.expense,
        categoryId: null,
        merchant: 'Taksit',
        note: null,
        transactionDate: DateTime(2026, 9, 15),
        source: TransactionSource.manual,
        isDeleted: false,
        installmentPlanId: 'plan-1',
        installmentNumber: 2,
        installmentCount: 4,
        installmentTotalAmount: 5000,
      );
      final before = GetCreditCardCurrentPeriodTransactionsUseCase(
        _TransactionRepository([installment]),
        const _StatementRepository(),
        clock: () => DateTime(2026, 9, 2),
      );
      final onDate = GetCreditCardCurrentPeriodTransactionsUseCase(
        _TransactionRepository([installment]),
        const _StatementRepository(),
        clock: () => DateTime(2026, 9, 15),
      );

      expect(await before.execute('card-1'), isEmpty);
      expect((await onDate.execute('card-1')).single.id, installment.id);
    },
  );
}

Transaction _customerCardPayment() => Transaction(
  id: 'customer-payment',
  accountId: null,
  creditCardId: 'card-1',
  amount: 22750,
  transactionType: TransactionType.expense,
  categoryId: null,
  merchant: 'Müşteriye ödeme',
  note: null,
  transactionDate: DateTime(2026, 8, 13),
  source: TransactionSource.manual,
  isDeleted: false,
  paymentGroupId: 'customer-payment-group',
  customerId: 'customer-1',
  customerBalanceDelta: 22750,
);

Transaction _cardDebtPayment() => Transaction(
  id: 'card-debt-payment',
  accountId: null,
  creditCardId: 'card-1',
  amount: 500,
  transactionType: TransactionType.income,
  categoryId: null,
  merchant: 'Kredi kartı ödemesi',
  note: null,
  transactionDate: DateTime(2026, 8, 13),
  source: TransactionSource.manual,
  isDeleted: false,
  paymentGroupId: 'card-debt-payment-group',
);

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

final class _StatementRepository implements CreditCardStatementRepository {
  const _StatementRepository();

  @override
  Future<void> create(CreditCardStatement statement) async {}

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async => const [];
}
