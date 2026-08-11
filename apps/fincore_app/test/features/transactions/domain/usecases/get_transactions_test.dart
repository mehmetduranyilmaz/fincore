import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/get_transactions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('orders transactions from newest to oldest', () async {
    final transactions = await GetTransactions(
      _Repository([
        _transaction('old', DateTime(2026, 1, 1)),
        _transaction('new', DateTime(2026, 8, 7)),
        _transaction('middle', DateTime(2026, 4, 3)),
      ]),
    ).execute(TransactionFilter());

    expect(transactions.map((item) => item.id), ['new', 'middle', 'old']);
  });
}

Transaction _transaction(String id, DateTime date) => Transaction(
  id: id,
  accountId: 'account-1',
  creditCardId: null,
  amount: 1,
  transactionType: TransactionType.expense,
  categoryId: null,
  merchant: id,
  note: null,
  transactionDate: date,
  source: TransactionSource.manual,
  isDeleted: false,
);

final class _Repository implements TransactionRepository {
  const _Repository(this.items);
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
