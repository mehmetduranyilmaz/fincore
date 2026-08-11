import 'package:fincore_app/features/accounts/domain/entities/account.dart';

abstract interface class AccountRepository {
  Future<List<Account>> getAccounts();
}
