import 'package:fincore_app/features/accounts/data/datasources/account_mock_data_source.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_command_repository.dart';

final class AccountCommandRepositoryImpl implements AccountCommandRepository {
  const AccountCommandRepositoryImpl(this._dataSource);

  final AccountCommandDataSource _dataSource;

  @override
  Future<void> archive(String accountId) => _dataSource.archive(accountId);
  @override
  Future<void> create(Account account) => _dataSource.insert(account);
  @override
  Future<Account?> getById(String accountId) => _dataSource.getById(accountId);
  @override
  Future<void> update(Account account) => _dataSource.replace(account);
}
