import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_movement.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/customers/domain/usecases/get_customer_movements.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates the balance after every movement chronologically', () async {
    final useCase = GetCustomerMovementsUseCase(
      _TransactionRepository([
        _movement(id: 'payment', date: DateTime(2026, 8, 2), balanceDelta: 70),
        _movement(
          id: 'collection',
          date: DateTime(2026, 8, 1),
          balanceDelta: -150,
        ),
        _openAccountExpense(
          id: 'training-expense',
          date: DateTime(2026, 7, 31),
          amount: 50,
        ),
      ]),
      const _CustomerRepository(),
    );

    final result = await useCase.execute('customer-1');

    expect(result.map((item) => item.transaction.id), [
      'training-expense',
      'collection',
      'payment',
    ]);
    expect(result.first.balanceAfterMovement, 50);
    expect(result.first.balanceSide, CustomerBalanceSide.debtor);
    expect(result[1].balanceAfterMovement, -100);
    expect(result.last.balanceAfterMovement, -30);
    expect(result.last.balanceSide, CustomerBalanceSide.creditor);
    expect(result.first.transaction.isCustomerCreditExpense, isTrue);
  });

  test('does not include deleted open-account expenses', () async {
    final useCase = GetCustomerMovementsUseCase(
      _TransactionRepository([
        _openAccountExpense(
          id: 'deleted-expense',
          date: DateTime(2026, 8, 1),
          amount: 50,
          isDeleted: true,
        ),
      ]),
      const _CustomerRepository(),
    );

    final result = await useCase.execute('customer-1');

    expect(result, isEmpty);
  });
}

Transaction _openAccountExpense({
  required String id,
  required DateTime date,
  required double amount,
  bool isDeleted = false,
}) {
  return Transaction(
    id: id,
    accountId: null,
    creditCardId: null,
    amount: amount,
    transactionType: TransactionType.expense,
    categoryId: 'training',
    merchant: 'Eğitim',
    note: null,
    transactionDate: date,
    source: TransactionSource.manual,
    isDeleted: isDeleted,
    customerId: 'customer-1',
    customerBalanceDelta: -amount,
  );
}

Transaction _movement({
  required String id,
  required DateTime date,
  required double balanceDelta,
}) {
  return Transaction(
    id: id,
    accountId: 'account-1',
    creditCardId: null,
    amount: balanceDelta.abs(),
    transactionType: TransactionType.transfer,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: date,
    source: TransactionSource.manual,
    isDeleted: false,
    paymentGroupId: 'group-$id',
    customerId: 'customer-1',
    customerBalanceDelta: balanceDelta,
  );
}

final class _CustomerRepository implements CustomerRepository {
  const _CustomerRepository();

  static const customer = Customer(
    id: 'customer-1',
    name: 'Müşteri',
    openingBalance: 100,
    currencyCode: 'TRY',
    isArchived: false,
  );

  @override
  Future<void> archive(String customerId) async {}

  @override
  Future<void> create(Customer customer) async {}

  @override
  Future<Customer?> getById(String customerId) async =>
      customerId == customer.id ? customer : null;

  @override
  Future<List<Customer>> getCustomers() async => const [customer];

  @override
  Future<void> update(Customer customer) async {}
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
