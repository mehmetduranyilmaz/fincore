import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/domain/usecases/get_account_movements.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'calculates running balances before applying the visible date filter',
    () async {
      final useCase = GetAccountMovementsUseCase(
        _Transactions([
          _transaction(
            'old-income',
            DateTime(2026, 1, 1),
            5000,
            TransactionType.income,
          ),
          _transaction(
            'payment',
            DateTime(2026, 7, 1),
            2000,
            TransactionType.expense,
          ),
          _transaction(
            'transfer-in',
            DateTime(2026, 8, 1),
            1000,
            TransactionType.transfer,
          ),
        ]),
        const _Accounts(),
      );

      final movements = await useCase.execute(
        accountId: 'account-1',
        startDate: DateTime(2026, 6),
        endDate: DateTime(2026, 8, 31),
      );

      expect(movements.map((item) => item.transaction.id), [
        'transfer-in',
        'payment',
      ]);
      expect(movements.map((item) => item.balanceAfterMovement), [
        14000,
        13000,
      ]);
    },
  );
}

Transaction _transaction(
  String id,
  DateTime date,
  double amount,
  TransactionType type,
) => Transaction(
  id: id,
  accountId: 'account-1',
  creditCardId: null,
  amount: type == TransactionType.transfer ? amount : amount.abs(),
  transactionType: type,
  categoryId: null,
  merchant: id,
  note: null,
  transactionDate: date,
  source: TransactionSource.manual,
  isDeleted: false,
  transferGroupId: type == TransactionType.transfer ? 'transfer' : null,
);

final class _Accounts implements AccountRepository {
  const _Accounts();

  @override
  Future<List<Account>> getAccounts() async => const [
    Account(
      id: 'account-1',
      name: 'Kasa',
      type: AccountType.cash,
      currencyCode: 'TRY',
      openingBalance: 10000,
      isArchived: false,
    ),
  ];
}

final class _Transactions implements TransactionRepository {
  const _Transactions(this.items);
  final List<Transaction> items;

  @override
  Future<void> create(Transaction transaction) async {}
  @override
  Future<void> createMany(List<Transaction> transactions) async {}
  @override
  Future<Transaction?> getById(String transactionId) async => null;
  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async =>
      items.where((item) {
        return (filter.endDate == null ||
            !item.transactionDate.isAfter(filter.endDate!));
      }).toList();
  @override
  Future<void> update(Transaction transaction) async {}
}
