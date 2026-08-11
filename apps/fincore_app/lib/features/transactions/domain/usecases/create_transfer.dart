import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_transfer_input.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

typedef TransferClock = DateTime Function();
typedef TransferIdGenerator = String Function();
typedef TransferGroupIdGenerator = String Function();

final class CreateTransferUseCase {
  CreateTransferUseCase(
    this._transactionRepository,
    this._accountRepository, {
    TransferClock? clock,
    TransferIdGenerator? transactionIdGenerator,
    TransferGroupIdGenerator? transferGroupIdGenerator,
  }) : _clock = clock ?? DateTime.now,
       _transactionIdGenerator =
           transactionIdGenerator ?? _generateTransactionId,
       _transferGroupIdGenerator =
           transferGroupIdGenerator ?? _generateTransferGroupId;

  final TransactionRepository _transactionRepository;
  final AccountRepository _accountRepository;
  final TransferClock _clock;
  final TransferIdGenerator _transactionIdGenerator;
  final TransferGroupIdGenerator _transferGroupIdGenerator;

  Future<List<Transaction>> execute(CreateTransferInput input) async {
    _validate(input);
    await _validateAccountsExist(input);

    final transferGroupId = _transferGroupIdGenerator();
    final description = input.description.trim();
    final transactions = List<Transaction>.unmodifiable([
      Transaction(
        id: _transactionIdGenerator(),
        accountId: input.fromAccountId,
        creditCardId: null,
        amount: -input.amount,
        transactionType: TransactionType.transfer,
        categoryId: null,
        merchant: description,
        note: null,
        transactionDate: input.transferDate,
        source: TransactionSource.manual,
        isDeleted: false,
        transferGroupId: transferGroupId,
      ),
      Transaction(
        id: _transactionIdGenerator(),
        accountId: input.toAccountId,
        creditCardId: null,
        amount: input.amount,
        transactionType: TransactionType.transfer,
        categoryId: null,
        merchant: description,
        note: null,
        transactionDate: input.transferDate,
        source: TransactionSource.manual,
        isDeleted: false,
        transferGroupId: transferGroupId,
      ),
    ]);

    await _transactionRepository.createMany(transactions);

    return transactions;
  }

  void _validate(CreateTransferInput input) {
    if (!input.amount.isFinite || input.amount <= 0) {
      throw ArgumentError.value(input.amount, 'amount');
    }

    if (input.fromAccountId == input.toAccountId) {
      throw ArgumentError.value(input.toAccountId, 'toAccountId');
    }

    if (input.description.trim().isEmpty) {
      throw ArgumentError.value(input.description, 'description');
    }

    if (input.transferDate.isAfter(_clock())) {
      throw ArgumentError.value(input.transferDate, 'transferDate');
    }
  }

  Future<void> _validateAccountsExist(CreateTransferInput input) async {
    final accounts = await _accountRepository.getAccounts();
    final accountIds = accounts.map((account) => account.id).toSet();

    if (!accountIds.contains(input.fromAccountId)) {
      throw ArgumentError.value(input.fromAccountId, 'fromAccountId');
    }

    if (!accountIds.contains(input.toAccountId)) {
      throw ArgumentError.value(input.toAccountId, 'toAccountId');
    }
  }

  static String _generateTransactionId() {
    return 'transfer-${DateTime.now().microsecondsSinceEpoch}';
  }

  static String _generateTransferGroupId() {
    return 'transfer-group-${DateTime.now().microsecondsSinceEpoch}';
  }
}
