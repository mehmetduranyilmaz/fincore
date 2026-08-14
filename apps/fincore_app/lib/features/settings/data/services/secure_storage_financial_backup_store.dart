import 'dart:convert';

import 'package:fincore_app/features/accounts/data/models/account_dto.dart';
import 'package:fincore_app/features/budgets/data/models/budget_dto.dart';
import 'package:fincore_app/features/categories/data/models/category_dto.dart';
import 'package:fincore_app/features/credit_cards/data/models/credit_card_dto.dart';
import 'package:fincore_app/features/credit_cards/data/models/credit_card_statement_dto.dart';
import 'package:fincore_app/features/customers/data/models/customer_dto.dart';
import 'package:fincore_app/features/settings/domain/errors/backup_exception.dart';
import 'package:fincore_app/features/settings/domain/services/financial_backup_store.dart';
import 'package:fincore_app/features/settings/data/services/backup_key_value_store.dart';
import 'package:fincore_app/features/transactions/data/models/transaction_dto.dart';

final class SecureStorageFinancialBackupStore implements FinancialBackupStore {
  const SecureStorageFinancialBackupStore(this._storage);

  static const String accountsKey = 'accounts_v1';
  static const String budgetsKey = 'budgets_v1';
  static const String categoriesKey = 'categories_v1';
  static const String categoryDefaultsVersionKey =
      'categories_defaults_version';
  static const String creditCardsKey = 'credit_cards_v1';
  static const String creditCardStatementsKey = 'credit_card_statements_v1';
  static const String customersKey = 'customers_v1';
  static const String transactionsKey = 'transactions_v1';

  static const Set<String> financialKeys = {
    accountsKey,
    budgetsKey,
    categoriesKey,
    categoryDefaultsVersionKey,
    creditCardsKey,
    creditCardStatementsKey,
    customersKey,
    transactionsKey,
  };

  final BackupKeyValueStore _storage;

  @override
  Future<Map<String, String?>> readFinancialData() async {
    return {for (final key in financialKeys) key: await _storage.read(key)};
  }

  @override
  Future<void> replaceFinancialData(Map<String, String?> data) async {
    _validate(data);
    final previous = await readFinancialData();
    try {
      await _writeAll(data);
    } on Object {
      try {
        await _writeAll(previous);
      } on Object {
        throw const BackupException(
          'Geri yükleme tamamlanamadı ve önceki veriler geri alınamadı.',
        );
      }
      throw const BackupException(
        'Geri yükleme tamamlanamadı; mevcut veriler korundu.',
      );
    }
  }

  Future<void> _writeAll(Map<String, String?> data) async {
    for (final key in financialKeys) {
      final value = data[key];
      if (value == null) {
        await _storage.delete(key);
      } else {
        await _storage.write(key, value);
      }
    }
  }

  static void _validate(Map<String, String?> data) {
    if (data.keys.toSet().difference(financialKeys).isNotEmpty ||
        financialKeys.difference(data.keys.toSet()).isNotEmpty) {
      throw const BackupException('Yedek veri kapsamı geçersiz.');
    }
    try {
      _validateList(data[accountsKey], AccountDto.fromJson);
      _validateList(data[budgetsKey], BudgetDto.fromJson);
      _validateList(data[categoriesKey], CategoryDto.fromJson);
      _validateList(data[creditCardsKey], CreditCardDto.fromJson);
      _validateList(
        data[creditCardStatementsKey],
        CreditCardStatementDto.fromJson,
      );
      _validateList(data[customersKey], CustomerDto.fromJson);
      _validateList(data[transactionsKey], TransactionDto.fromJson);
      final defaultsVersion = data[categoryDefaultsVersionKey];
      if (defaultsVersion != null && int.tryParse(defaultsVersion) == null) {
        throw const FormatException('Invalid defaults version.');
      }
    } on Object {
      throw const BackupException('Yedek içindeki finansal veriler geçersiz.');
    }
  }

  static void _validateList<T>(
    String? value,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    if (value == null) return;
    final decoded = jsonDecode(value);
    if (decoded is! List<Object?>) {
      throw const FormatException('Expected list.');
    }
    for (final item in decoded) {
      if (item is! Map) throw const FormatException('Expected object.');
      fromJson(
        item.map((key, value) {
          if (key is! String) throw const FormatException('Invalid key.');
          return MapEntry(key, value);
        }),
      );
    }
  }
}
