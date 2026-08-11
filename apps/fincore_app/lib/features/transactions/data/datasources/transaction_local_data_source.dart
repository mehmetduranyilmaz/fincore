import 'dart:convert';

import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:fincore_app/features/transactions/data/models/transaction_dto.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_filter.dart';

final class TransactionLocalDataSource
    implements TransactionDataSource, InstallmentTransactionDataSource {
  const TransactionLocalDataSource(this._storage);

  static const String _storageKey = 'transactions_v1';

  final SecureStorageService _storage;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    final transactions = await _readAll();
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
      transactions.where((transaction) {
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
        return searchText.isEmpty ||
            transaction.merchant.toLowerCase().contains(searchText) ||
            (transaction.note?.toLowerCase().contains(searchText) ?? false);
      }),
    );
  }

  @override
  Future<Transaction?> findById(String transactionId) async {
    for (final transaction in await _readAll()) {
      if (transaction.id == transactionId) {
        return transaction;
      }
    }
    return null;
  }

  @override
  Future<void> insert(Transaction transaction) async {
    final transactions = await _readAll();
    _ensureIdsAvailable(transactions, [transaction]);
    await _writeAll([transaction, ...transactions]);
  }

  @override
  Future<void> insertMany(List<Transaction> transactions) async {
    final current = await _readAll();
    _ensureIdsAvailable(current, transactions);
    await _writeAll([...transactions.reversed, ...current]);
  }

  @override
  Future<void> replace(Transaction transaction) async {
    final transactions = await _readAll();
    final index = transactions.indexWhere((item) => item.id == transaction.id);
    if (index < 0) {
      throw StateError('Transaction not found.');
    }
    transactions[index] = transaction;
    await _writeAll(transactions);
  }

  @override
  Future<bool> hasAnyCreditCardMovement(String creditCardId) async {
    return (await _readAll()).any(
      (transaction) =>
          !transaction.isDeleted && transaction.creditCardId == creditCardId,
    );
  }

  @override
  Future<bool> hasAnyAccountMovement(String accountId) async {
    return (await _readAll()).any(
      (transaction) =>
          !transaction.isDeleted && transaction.accountId == accountId,
    );
  }

  @override
  Future<bool> hasAnyCategoryMovement(String categoryId) async {
    return (await _readAll()).any(
      (transaction) =>
          !transaction.isDeleted && transaction.categoryId == categoryId,
    );
  }

  @override
  Future<bool> hasAnyCustomerMovement(String customerId) async {
    return (await _readAll()).any(
      (transaction) =>
          !transaction.isDeleted && transaction.customerId == customerId,
    );
  }

  @override
  Future<void> removeMany(Set<String> transactionIds) async {
    final transactions = await _readAll();
    if (transactionIds.isEmpty ||
        transactionIds.any(
          (id) => !transactions.any((transaction) => transaction.id == id),
        )) {
      throw StateError('Transaction not found.');
    }
    transactions.removeWhere(
      (transaction) => transactionIds.contains(transaction.id),
    );
    await _writeAll(transactions);
  }

  @override
  Future<void> insertPlan(List<Transaction> installments) async {
    if (installments.isEmpty) {
      throw ArgumentError.value(installments, 'installments');
    }
    final transactions = await _readAll();
    _ensureIdsAvailable(transactions, installments);
    await _writeAll([...installments.reversed, ...transactions]);
  }

  @override
  Future<void> replaceWithPlan(List<Transaction> installments) async {
    if (installments.length < 2) {
      throw ArgumentError.value(installments, 'installments');
    }
    final transactions = await _readAll();
    final index = transactions.indexWhere(
      (item) => item.id == installments.first.id,
    );
    if (index < 0) {
      throw StateError('Transaction not found.');
    }
    _ensureIdsAvailable(transactions, installments.skip(1).toList());
    transactions[index] = installments.first;
    transactions.insertAll(0, installments.skip(1).toList().reversed);
    await _writeAll(transactions);
  }

  Future<List<Transaction>> _readAll() async {
    final value = await _storage.read(key: _storageKey);
    if (value == null || value.isEmpty) {
      await _writeAll(const []);
      return [];
    }
    final json = jsonDecode(value);
    if (json is! List<Object?>) {
      throw const FormatException('Invalid transaction storage.');
    }
    final transactions = [
      for (final item in json)
        TransactionDto.fromJson(item! as Map<String, Object?>).transaction,
    ];
    final cleaned = transactions
        .where((item) => !_legacySeedIds.contains(item.id) && !item.isDeleted)
        .toList();
    if (cleaned.length != transactions.length) {
      await _writeAll(cleaned);
    }
    return cleaned;
  }

  Future<void> _writeAll(List<Transaction> transactions) {
    return _storage.write(
      key: _storageKey,
      value: jsonEncode([
        for (final transaction in transactions)
          TransactionDto(transaction).toJson(),
      ]),
    );
  }

  static void _ensureIdsAvailable(
    List<Transaction> current,
    List<Transaction> additions,
  ) {
    final ids = additions.map((item) => item.id).toSet();
    if (ids.length != additions.length ||
        current.any((item) => ids.contains(item.id))) {
      throw StateError('Transaction already exists.');
    }
  }

  static const Set<String> _legacySeedIds = {
    'transaction-1',
    'transaction-2',
    'transaction-3',
    'transaction-4',
    'transaction-5',
    'transaction-6',
    'transaction-7',
    'transaction-8',
    'transaction-9',
    'transaction-10',
    'transaction-11',
    'transaction-12',
  };
}
