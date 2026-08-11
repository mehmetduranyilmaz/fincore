import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';

abstract interface class TransactionDataSource {
  Future<List<Transaction>> getTransactions(TransactionFilter filter);

  Future<Transaction?> findById(String transactionId);

  Future<void> insert(Transaction transaction);

  Future<void> insertMany(List<Transaction> transactions);

  Future<void> replace(Transaction transaction);

  Future<void> removeMany(Set<String> transactionIds);

  Future<bool> hasAnyCreditCardMovement(String creditCardId);

  Future<bool> hasAnyAccountMovement(String accountId);

  Future<bool> hasAnyCategoryMovement(String categoryId);

  Future<bool> hasAnyCustomerMovement(String customerId);
}

abstract interface class InstallmentTransactionDataSource {
  Future<void> insertPlan(List<Transaction> installments);

  Future<void> replaceWithPlan(List<Transaction> installments);
}

final class TransactionMockDataSource
    implements TransactionDataSource, InstallmentTransactionDataSource {
  TransactionMockDataSource({List<Transaction>? initialTransactions})
    : _transactions = [
        ...?initialTransactions,
        if (initialTransactions == null) ...createDefaultTransactions(),
      ];

  final List<Transaction> _transactions;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    final searchText = filter.searchText.trim().toLowerCase();
    final startDate = filter.startDate == null
        ? null
        : DateTime(
            filter.startDate!.year,
            filter.startDate!.month,
            filter.startDate!.day,
          );
    final endDate = filter.endDate == null
        ? null
        : DateTime(
            filter.endDate!.year,
            filter.endDate!.month,
            filter.endDate!.day + 1,
          );

    return List.unmodifiable(
      _transactions.where((transaction) {
        if (transaction.isDeleted) {
          return false;
        }
        if (filter.transactionTypes.isNotEmpty &&
            !filter.transactionTypes.contains(transaction.transactionType)) {
          return false;
        }
        if (filter.accountId != null &&
            transaction.accountId != filter.accountId) {
          return false;
        }
        if (filter.creditCardId != null &&
            transaction.creditCardId != filter.creditCardId) {
          return false;
        }
        if (startDate != null &&
            transaction.transactionDate.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && !transaction.transactionDate.isBefore(endDate)) {
          return false;
        }
        if (searchText.isNotEmpty &&
            !transaction.merchant.toLowerCase().contains(searchText) &&
            !(transaction.note?.toLowerCase().contains(searchText) ?? false)) {
          return false;
        }
        return true;
      }),
    );
  }

  @override
  Future<Transaction?> findById(String transactionId) async {
    for (final transaction in _transactions) {
      if (transaction.id == transactionId) {
        return transaction;
      }
    }
    return null;
  }

  @override
  Future<void> insert(Transaction transaction) async {
    _transactions.insert(0, transaction);
  }

  @override
  Future<void> insertMany(List<Transaction> transactions) async {
    _transactions.insertAll(0, transactions);
  }

  @override
  Future<void> replace(Transaction transaction) async {
    final index = _transactions.indexWhere(
      (current) => current.id == transaction.id,
    );
    if (index == -1) {
      throw StateError('Transaction not found.');
    }
    _transactions[index] = transaction;
  }

  @override
  Future<bool> hasAnyCreditCardMovement(String creditCardId) async {
    return _transactions.any(
      (transaction) =>
          !transaction.isDeleted && transaction.creditCardId == creditCardId,
    );
  }

  @override
  Future<bool> hasAnyAccountMovement(String accountId) async {
    return _transactions.any(
      (transaction) =>
          !transaction.isDeleted && transaction.accountId == accountId,
    );
  }

  @override
  Future<bool> hasAnyCategoryMovement(String categoryId) async {
    return _transactions.any(
      (transaction) =>
          !transaction.isDeleted && transaction.categoryId == categoryId,
    );
  }

  @override
  Future<bool> hasAnyCustomerMovement(String customerId) async {
    return _transactions.any(
      (transaction) =>
          !transaction.isDeleted && transaction.customerId == customerId,
    );
  }

  @override
  Future<void> removeMany(Set<String> transactionIds) async {
    if (transactionIds.isEmpty ||
        transactionIds.any(
          (id) => !_transactions.any((transaction) => transaction.id == id),
        )) {
      throw StateError('Transaction not found.');
    }
    _transactions.removeWhere(
      (transaction) => transactionIds.contains(transaction.id),
    );
  }

  @override
  Future<void> insertPlan(List<Transaction> installments) async {
    if (installments.isEmpty) {
      throw ArgumentError.value(installments, 'installments');
    }
    final ids = installments.map((item) => item.id).toSet();
    if (ids.length != installments.length ||
        _transactions.any((item) => ids.contains(item.id))) {
      throw StateError('Installment transaction already exists.');
    }
    _transactions.insertAll(0, installments.reversed);
  }

  @override
  Future<void> replaceWithPlan(List<Transaction> installments) async {
    if (installments.length < 2) {
      throw ArgumentError.value(installments, 'installments');
    }
    final originalIndex = _transactions.indexWhere(
      (item) => item.id == installments.first.id,
    );
    if (originalIndex < 0) {
      throw StateError('Transaction not found.');
    }
    final newIds = installments.skip(1).map((item) => item.id).toSet();
    if (newIds.length != installments.length - 1 ||
        _transactions.any((item) => newIds.contains(item.id))) {
      throw StateError('Installment transaction already exists.');
    }

    _transactions[originalIndex] = installments.first;
    _transactions.insertAll(0, installments.skip(1).toList().reversed);
  }

  static List<Transaction> createDefaultTransactions() => const [];
}
