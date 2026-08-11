import 'package:fincore_app/features/accounts/data/datasources/account_mock_data_source.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';

final class AccountRepositoryImpl implements AccountRepository {
  const AccountRepositoryImpl(this._dataSource);

  final AccountDataSource _dataSource;

  @override
  Future<List<Account>> getAccounts() async {
    final accounts = await _dataSource.getAccounts();
    return List.unmodifiable(accounts);
  }
}
