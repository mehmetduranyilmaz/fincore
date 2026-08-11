import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/get_transaction_details.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../transactions_test_data.dart';

void main() {
  test('returns the transaction matching the requested id', () async {
    final transactions = createTransactions();
    final useCase = GetTransactionDetailsUseCase(
      _TransactionRepository(transactions),
    );

    final result = await useCase.execute('transaction-2');

    expect(result, transactions.last);
  });

  test('rejects an empty transaction id', () {
    final useCase = GetTransactionDetailsUseCase(
      _TransactionRepository(createTransactions()),
    );

    expect(() => useCase.execute('  '), throwsArgumentError);
  });
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.transactions);

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
    return transactions;
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
