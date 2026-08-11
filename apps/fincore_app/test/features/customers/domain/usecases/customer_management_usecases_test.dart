import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/entities/create_customer_input.dart';
import 'package:fincore_app/features/customers/domain/entities/update_customer_input.dart';
import 'package:fincore_app/features/customers/domain/errors/customer_operation_exception.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_usage_repository.dart';
import 'package:fincore_app/features/customers/domain/usecases/calculate_customer_balance.dart';
import 'package:fincore_app/features/customers/domain/usecases/create_customer.dart';
import 'package:fincore_app/features/customers/domain/usecases/delete_customer.dart';
import 'package:fincore_app/features/customers/domain/usecases/update_customer.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects a duplicate customer name with Turkish casing', () {
    final customers = _CustomerRepository(_customer);

    expect(
      () => CreateCustomerUseCase(customers).execute(
        const CreateCustomerInput(
          name: '  MÜŞTERİ ',
          openingBalance: 0,
          currencyCode: 'TRY',
        ),
      ),
      throwsA(isA<CustomerOperationException>()),
    );
  });

  test(
    'updates customer name while preserving a ledger with movements',
    () async {
      final customers = _CustomerRepository(_customer);
      final transactions = _TransactionRepository([_movement(-100)]);
      final useCase = UpdateCustomerUseCase(customers, transactions);

      final updated = await useCase.execute(
        const UpdateCustomerInput(
          customerId: 'customer-1',
          name: 'Yeni Ad',
          openingBalance: 100,
          currencyCode: 'TRY',
        ),
      );

      expect(updated.name, 'Yeni Ad');
      expect(updated.openingBalance, 100);
      expect(customers.customer, updated);
    },
  );

  test('rejects opening balance changes after a customer movement', () {
    final customers = _CustomerRepository(_customer);
    final useCase = UpdateCustomerUseCase(
      customers,
      _TransactionRepository([_movement(-100)]),
    );

    expect(
      () => useCase.execute(
        const UpdateCustomerInput(
          customerId: 'customer-1',
          name: 'Müşteri',
          openingBalance: 200,
          currencyCode: 'TRY',
        ),
      ),
      throwsA(isA<CustomerOperationException>()),
    );
  });

  test('does not archive a zero-balance customer with movements', () async {
    final customers = _CustomerRepository(_customer);
    final transactions = _TransactionRepository([_movement(-100)]);
    final balance = CalculateCustomerBalanceUseCase(customers, transactions);

    await expectLater(
      DeleteCustomerUseCase(
        customers,
        balance,
        const _CustomerUsageRepository(true),
      ).execute(_customer.id),
      throwsA(isA<CustomerOperationException>()),
    );

    expect(customers.customer.isArchived, isFalse);
  });

  test('archives an unused customer whose balance is zero', () async {
    final customers = _CustomerRepository(
      _customer.copyWith(openingBalance: 0),
    );
    final balance = CalculateCustomerBalanceUseCase(
      customers,
      _TransactionRepository(const []),
    );

    await DeleteCustomerUseCase(
      customers,
      balance,
      const _CustomerUsageRepository(false),
    ).execute(_customer.id);

    expect(customers.customer.isArchived, isTrue);
  });

  test('rejects deletion while the customer has an open balance', () {
    final customers = _CustomerRepository(_customer);
    final balance = CalculateCustomerBalanceUseCase(
      customers,
      _TransactionRepository(const []),
    );

    expect(
      () => DeleteCustomerUseCase(
        customers,
        balance,
        const _CustomerUsageRepository(false),
      ).execute(_customer.id),
      throwsA(isA<CustomerOperationException>()),
    );
  });
}

final class _CustomerUsageRepository implements CustomerUsageRepository {
  const _CustomerUsageRepository(this.hasMovements);

  final bool hasMovements;

  @override
  Future<bool> hasUsage(String customerId) async => hasMovements;
}

const _customer = Customer(
  id: 'customer-1',
  name: 'Müşteri',
  openingBalance: 100,
  currencyCode: 'TRY',
  isArchived: false,
);

Transaction _movement(double delta) {
  return Transaction(
    id: 'movement-1',
    accountId: 'account-1',
    creditCardId: null,
    amount: delta.abs(),
    transactionType: TransactionType.transfer,
    categoryId: null,
    merchant: 'Tahsilat',
    note: null,
    transactionDate: DateTime(2026, 8, 7),
    source: TransactionSource.manual,
    isDeleted: false,
    customerId: _customer.id,
    customerBalanceDelta: delta,
  );
}

final class _CustomerRepository implements CustomerRepository {
  _CustomerRepository(this.customer);
  Customer customer;

  @override
  Future<void> create(Customer customer) async => this.customer = customer;
  @override
  Future<Customer?> getById(String customerId) async =>
      customer.id == customerId && !customer.isArchived ? customer : null;
  @override
  Future<List<Customer>> getCustomers() async =>
      customer.isArchived ? const [] : [customer];
  @override
  Future<void> update(Customer customer) async => this.customer = customer;
  @override
  Future<void> archive(String customerId) async {
    customer = customer.copyWith(isArchived: true);
  }
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.transactions);
  final List<Transaction> transactions;
  @override
  Future<void> create(Transaction transaction) async {}
  @override
  Future<void> createMany(List<Transaction> transactions) async {}
  @override
  Future<Transaction?> getById(String transactionId) async => null;
  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async =>
      transactions;
  @override
  Future<void> update(Transaction transaction) async {}
}
