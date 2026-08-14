import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/entities/update_transaction_input.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/update_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _TransactionRepository repository;
  late UpdateTransactionUseCase useCase;

  setUp(() {
    repository = _TransactionRepository([_manualExpense()]);
    useCase = UpdateTransactionUseCase(
      repository,
      customerRepository: const _CustomerRepository(),
      clock: () => DateTime(2026, 7, 25, 12),
    );
  });

  test('updates editable fields while preserving type and source', () async {
    final updated = await useCase.execute(_input());

    expect(updated.amount, 450);
    expect(updated.merchant, 'Updated expense');
    expect(updated.categoryId, 'category-updated');
    expect(updated.transactionType, TransactionType.expense);
    expect(updated.source, TransactionSource.manual);
    expect(repository.transactions.single, updated);
  });

  test('rejects transfer and imported transactions', () {
    for (final transaction in [_transfer(), _importedExpense()]) {
      final restrictedUseCase = UpdateTransactionUseCase(
        _TransactionRepository([transaction]),
        clock: () => DateTime(2026, 7, 25, 12),
      );

      expect(
        () => restrictedUseCase.execute(_input(transactionId: transaction.id)),
        throwsUnsupportedError,
      );
    }
  });

  test('rejects invalid amount, description, and future date', () {
    expect(() => useCase.execute(_input(amount: 0)), throwsArgumentError);
    expect(
      () => useCase.execute(_input(description: '  ')),
      throwsArgumentError,
    );
    expect(
      () => useCase.execute(_input(transactionDate: DateTime(2026, 7, 26))),
      throwsArgumentError,
    );
  });

  test('rejects a credit card source for income', () {
    final income = _manualIncome();
    final incomeUseCase = UpdateTransactionUseCase(
      _TransactionRepository([income]),
      clock: () => DateTime(2026, 7, 25, 12),
    );

    expect(
      () => incomeUseCase.execute(
        _input(
          transactionId: income.id,
          accountId: null,
          creditCardId: 'credit-card-1',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('converts a cash expense to an open-account expense', () async {
    final updated = await useCase.execute(
      _input(accountId: null, customerId: 'customer-1', amount: 900),
    );

    expect(updated.accountId, isNull);
    expect(updated.creditCardId, isNull);
    expect(updated.customerId, 'customer-1');
    expect(updated.customerBalanceDelta, -900);
    expect(updated.isCustomerCreditExpense, isTrue);
  });
}

UpdateTransactionInput _input({
  String transactionId = 'manual-expense',
  String? accountId = 'account-1',
  String? creditCardId,
  String? customerId,
  double amount = 450,
  String description = '  Updated expense  ',
  DateTime? transactionDate,
}) {
  return UpdateTransactionInput(
    transactionId: transactionId,
    accountId: accountId,
    creditCardId: creditCardId,
    customerId: customerId,
    amount: amount,
    description: description,
    categoryId: 'category-updated',
    transactionDate: transactionDate ?? DateTime(2026, 7, 25),
  );
}

final class _CustomerRepository implements CustomerRepository {
  const _CustomerRepository();

  static const customer = Customer(
    id: 'customer-1',
    name: 'Eğitim Kurumu',
    openingBalance: 0,
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

Transaction _manualExpense() {
  return Transaction(
    id: 'manual-expense',
    accountId: 'account-1',
    creditCardId: null,
    amount: 100,
    transactionType: TransactionType.expense,
    categoryId: null,
    merchant: 'Gider',
    note: null,
    transactionDate: DateTime(2026, 7, 24),
    source: TransactionSource.manual,
    isDeleted: false,
  );
}

Transaction _manualIncome() {
  return Transaction(
    id: 'manual-income',
    accountId: 'account-1',
    creditCardId: null,
    amount: 100,
    transactionType: TransactionType.income,
    categoryId: null,
    merchant: 'Gelir',
    note: null,
    transactionDate: DateTime(2026, 7, 24),
    source: TransactionSource.manual,
    isDeleted: false,
  );
}

Transaction _transfer() {
  return Transaction(
    id: 'transfer',
    accountId: 'account-1',
    creditCardId: null,
    amount: -100,
    transactionType: TransactionType.transfer,
    categoryId: null,
    merchant: 'Transfer',
    note: null,
    transactionDate: DateTime(2026, 7, 24),
    source: TransactionSource.manual,
    isDeleted: false,
    transferGroupId: 'transfer-group',
  );
}

Transaction _importedExpense() {
  return Transaction(
    id: 'imported-expense',
    accountId: 'account-1',
    creditCardId: null,
    amount: 100,
    transactionType: TransactionType.expense,
    categoryId: null,
    merchant: 'Imported',
    note: null,
    transactionDate: DateTime(2026, 7, 24),
    source: TransactionSource.import,
    isDeleted: false,
  );
}

final class _TransactionRepository implements TransactionRepository {
  _TransactionRepository(List<Transaction> transactions)
    : transactions = [...transactions];

  final List<Transaction> transactions;

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<Transaction?> getById(String transactionId) async {
    for (final transaction in transactions) {
      if (transaction.id == transactionId) {
        return transaction;
      }
    }
    return null;
  }

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return List.unmodifiable(transactions);
  }

  @override
  Future<void> update(Transaction transaction) async {
    final index = transactions.indexWhere(
      (current) => current.id == transaction.id,
    );
    transactions[index] = transaction;
  }
}
