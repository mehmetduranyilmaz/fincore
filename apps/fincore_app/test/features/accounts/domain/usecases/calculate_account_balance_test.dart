import 'package:fincore_app/features/accounts/domain/entities/account_balance.dart';
import 'package:fincore_app/features/accounts/domain/usecases/calculate_account_balance.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('derives balance totals from active account transactions', () async {
    final useCase = CalculateAccountBalanceUseCase(
      _TransactionRepository([
        _transaction(id: 'income', amount: 1000, type: TransactionType.income),
        _transaction(id: 'expense', amount: 200, type: TransactionType.expense),
        _transaction(
          id: 'transfer-out',
          amount: -300,
          type: TransactionType.transfer,
        ),
        _transaction(
          id: 'transfer-in',
          amount: 150,
          type: TransactionType.transfer,
        ),
        _transaction(
          id: 'deleted-income',
          amount: 5000,
          type: TransactionType.income,
          isDeleted: true,
        ),
        _transaction(
          id: 'other-account',
          accountId: 'account-2',
          amount: 999,
          type: TransactionType.income,
        ),
      ]),
    );

    final result = await useCase.execute('account-1');

    expect(
      result,
      const AccountBalance(
        currentBalance: 650,
        totalIncome: 1150,
        totalExpense: 500,
      ),
    );
  });

  test('returns zero totals when an account has no transactions', () async {
    final useCase = CalculateAccountBalanceUseCase(
      _TransactionRepository(const []),
    );

    final result = await useCase.execute('account-1');

    expect(
      result,
      const AccountBalance(currentBalance: 0, totalIncome: 0, totalExpense: 0),
    );
  });
}

Transaction _transaction({
  required String id,
  String accountId = 'account-1',
  required double amount,
  required TransactionType type,
  bool isDeleted = false,
}) {
  return Transaction(
    id: id,
    accountId: accountId,
    creditCardId: null,
    amount: amount,
    transactionType: type,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: DateTime(2026, 7, 25),
    source: TransactionSource.manual,
    isDeleted: isDeleted,
    transferGroupId: type == TransactionType.transfer ? 'group-$id' : null,
  );
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
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return transactions;
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
