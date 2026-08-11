import 'dart:convert';

import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/accounts/data/datasources/account_mock_data_source.dart';
import 'package:fincore_app/features/accounts/data/models/account_dto.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';

final class AccountLocalDataSource
    implements AccountDataSource, AccountCommandDataSource {
  const AccountLocalDataSource(this._storage);

  static const String _storageKey = 'accounts_v1';
  final SecureStorageService _storage;

  @override
  Future<List<Account>> getAccounts() async {
    return List.unmodifiable(
      (await _readAll()).where((account) => !account.isArchived),
    );
  }

  @override
  Future<Account?> getById(String accountId) async {
    for (final account in await _readAll()) {
      if (account.id == accountId && !account.isArchived) return account;
    }
    return null;
  }

  @override
  Future<void> insert(Account account) async {
    final accounts = await _readAll();
    if (accounts.any((item) => item.id == account.id)) {
      throw StateError('Account already exists.');
    }
    await _writeAll([...accounts, account]);
  }

  @override
  Future<void> replace(Account account) async {
    final accounts = await _readAll();
    final index = accounts.indexWhere((item) => item.id == account.id);
    if (index < 0 || accounts[index].isArchived) {
      throw StateError('Account not found.');
    }
    accounts[index] = account;
    await _writeAll(accounts);
  }

  @override
  Future<void> archive(String accountId) async {
    final accounts = await _readAll();
    final index = accounts.indexWhere((item) => item.id == accountId);
    if (index < 0 || accounts[index].isArchived) {
      throw StateError('Account not found.');
    }
    accounts[index] = accounts[index].copyWith(isArchived: true);
    await _writeAll(accounts);
  }

  Future<List<Account>> _readAll() async {
    final value = await _storage.read(key: _storageKey);
    if (value == null || value.isEmpty) {
      await _writeAll(const []);
      return [];
    }
    final json = jsonDecode(value);
    if (json is! List<Object?>) {
      throw const FormatException('Invalid account storage.');
    }
    final accounts = [
      for (final item in json)
        AccountDto.fromJson(item! as Map<String, Object?>).account,
    ];
    final cleaned = accounts
        .where((account) => !_legacySeedIds.contains(account.id))
        .toList();
    if (cleaned.length != accounts.length) {
      await _writeAll(cleaned);
    }
    return cleaned;
  }

  Future<void> _writeAll(List<Account> accounts) {
    return _storage.write(
      key: _storageKey,
      value: jsonEncode([
        for (final account in accounts) AccountDto(account).toJson(),
      ]),
    );
  }

  static const Set<String> _legacySeedIds = {
    'account-1',
    'account-2',
    'account-4',
    'account-5',
  };
}
