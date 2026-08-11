import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:fincore_app/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:fincore_app/features/accounts/domain/usecases/calculate_account_balance.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/customers/domain/usecases/calculate_customer_balance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deletes every transaction in the same installment plan', () async {
    final dataSource = TransactionMockDataSource(
      initialTransactions: [
        _installment('first', 1),
        _installment('second', 2),
      ],
    );
    final repository = TransactionRepositoryImpl(dataSource);

    await DeleteTransactionUseCase(repository, repository).execute('first');

    expect(await repository.getTransactions(TransactionFilter()), isEmpty);
    expect(await repository.getById('first'), isNull);
    expect(await repository.getById('second'), isNull);
  });

  test('rejects deletion of imported transactions', () async {
    final imported = Transaction(
      id: 'imported',
      accountId: 'account-1',
      creditCardId: null,
      amount: 10,
      transactionType: TransactionType.expense,
      categoryId: null,
      merchant: 'Imported',
      note: null,
      transactionDate: DateTime(2026, 8, 7),
      source: TransactionSource.import,
      isDeleted: false,
    );
    final repository = TransactionRepositoryImpl(
      TransactionMockDataSource(initialTransactions: [imported]),
    );

    expect(
      () =>
          DeleteTransactionUseCase(repository, repository).execute(imported.id),
      throwsStateError,
    );
  });

  test('deleting a customer collection reverses both ledgers', () async {
    final opening = Transaction(
      id: 'opening-income',
      accountId: 'account-1',
      creditCardId: null,
      amount: 1000,
      transactionType: TransactionType.income,
      categoryId: null,
      merchant: 'Açılış',
      note: null,
      transactionDate: DateTime(2026, 8, 1),
      source: TransactionSource.manual,
      isDeleted: false,
    );
    final collection = Transaction(
      id: 'customer-collection',
      accountId: 'account-1',
      creditCardId: null,
      amount: 100,
      transactionType: TransactionType.transfer,
      categoryId: null,
      merchant: 'Tahsilat',
      note: null,
      transactionDate: DateTime(2026, 8, 7),
      source: TransactionSource.manual,
      isDeleted: false,
      paymentGroupId: 'customer-group',
      customerId: 'customer-1',
      customerBalanceDelta: -100,
    );
    final repository = TransactionRepositoryImpl(
      TransactionMockDataSource(initialTransactions: [opening, collection]),
    );
    final customerBalance = CalculateCustomerBalanceUseCase(
      const _CustomerRepository(),
      repository,
    );
    final accountBalance = CalculateAccountBalanceUseCase(repository);
    expect(await customerBalance.execute('customer-1'), 400);
    expect((await accountBalance.execute('account-1')).currentBalance, 1100);

    await DeleteTransactionUseCase(
      repository,
      repository,
    ).execute(collection.id);

    expect(await customerBalance.execute('customer-1'), 500);
    expect((await accountBalance.execute('account-1')).currentBalance, 1000);
  });
}

final class _CustomerRepository implements CustomerRepository {
  const _CustomerRepository();

  static const customer = Customer(
    id: 'customer-1',
    name: 'Müşteri',
    openingBalance: 500,
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

Transaction _installment(String id, int number) {
  return Transaction(
    id: id,
    accountId: null,
    creditCardId: 'card-1',
    amount: 50,
    transactionType: TransactionType.expense,
    categoryId: null,
    merchant: 'Market',
    note: null,
    transactionDate: DateTime(2026, 8 + number - 1, 7),
    source: TransactionSource.manual,
    isDeleted: false,
    installmentPlanId: 'plan-1',
    installmentNumber: number,
    installmentCount: 2,
    installmentTotalAmount: 100,
  );
}
