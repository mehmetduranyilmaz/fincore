import 'package:fincore_app/features/accounts/domain/entities/account.dart';

abstract interface class AccountCommandRepository {
  Future<Account?> getById(String accountId);

  Future<void> create(Account account);

  Future<void> update(Account account);

  Future<void> archive(String accountId);
}
