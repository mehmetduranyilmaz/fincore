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
      ]),
      const _CustomerRepository(),
    );

    final result = await useCase.execute('customer-1');

    expect(result.map((item) => item.transaction.id), [
      'payment',
      'collection',
    ]);
    expect(result.first.balanceAfterMovement, 20);
    expect(result.first.balanceSide, CustomerBalanceSide.debtor);
    expect(result.last.balanceAfterMovement, -50);
    expect(result.last.balanceSide, CustomerBalanceSide.creditor);
  });
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
