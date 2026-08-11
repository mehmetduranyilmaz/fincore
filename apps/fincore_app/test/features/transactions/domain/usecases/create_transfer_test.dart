import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_transfer_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_transfer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _TransactionRepository transactionRepository;
  late CreateTransferUseCase useCase;
  late int id;

  setUp(() {
    id = 0;
    transactionRepository = _TransactionRepository();
    useCase = CreateTransferUseCase(
      transactionRepository,
      const _AccountRepository(),
      clock: () => DateTime(2026, 7, 25, 12),
      transactionIdGenerator: () => 'transaction-${++id}',
      transferGroupIdGenerator: () => 'transfer-group-1',
    );
  });

  test('creates and persists an ordered transfer pair', () async {
    final transactions = await useCase.execute(_input());

    expect(transactions, hasLength(2));
    expect(transactions.first.id, 'transaction-1');
    expect(transactions.first.accountId, 'account-1');
    expect(transactions.first.amount, -500);
    expect(transactions.last.id, 'transaction-2');
    expect(transactions.last.accountId, 'account-2');
    expect(transactions.last.amount, 500);
    expect(
      transactions.map((transaction) => transaction.transactionType),
      everyElement(TransactionType.transfer),
    );
    expect(
      transactions.map((transaction) => transaction.source),
      everyElement(TransactionSource.manual),
    );
    expect(
      transactions.map((transaction) => transaction.transferGroupId).toSet(),
      {'transfer-group-1'},
    );
    expect(transactionRepository.transactions, transactions);
  });

  test('rejects a non-positive amount', () {
    expect(() => useCase.execute(_input(amount: 0)), throwsArgumentError);
  });

  test('rejects identical source and destination accounts', () {
    expect(
      () => useCase.execute(_input(toAccountId: 'account-1')),
      throwsArgumentError,
    );
  });

  test('rejects an account that does not exist', () {
    expect(
      () => useCase.execute(_input(toAccountId: 'missing-account')),
      throwsArgumentError,
    );
  });

  test('rejects a future transfer date', () {
    expect(
      () => useCase.execute(_input(transferDate: DateTime(2026, 7, 26))),
      throwsArgumentError,
    );
  });
}

CreateTransferInput _input({
  String toAccountId = 'account-2',
  double amount = 500,
  DateTime? transferDate,
}) {
  return CreateTransferInput(
    fromAccountId: 'account-1',
    toAccountId: toAccountId,
    amount: amount,
    description: 'Internal transfer',
    transferDate: transferDate ?? DateTime(2026, 7, 25),
  );
}

final class _TransactionRepository implements TransactionRepository {
  final List<Transaction> transactions = [];

  @override
  Future<void> create(Transaction transaction) async {
    transactions.add(transaction);
  }

  @override
  Future<void> createMany(List<Transaction> transactions) async {
    this.transactions.addAll(transactions);
  }

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return List.unmodifiable(transactions);
  }

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<void> update(Transaction transaction) async {}
}

final class _AccountRepository implements AccountRepository {
  const _AccountRepository();

  @override
  Future<List<Account>> getAccounts() async {
    return const [
      Account(
        id: 'account-1',
        name: 'Source',
        type: AccountType.checking,
        currencyCode: 'TRY',
        isArchived: false,
      ),
      Account(
        id: 'account-2',
        name: 'Destination',
        type: AccountType.savings,
        currencyCode: 'TRY',
        isArchived: false,
      ),
    ];
  }
}
