import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';

final class GetAccounts {
  const GetAccounts(this._repository);

  final AccountRepository _repository;

  Future<List<Account>> execute() async {
    final accounts = [...await _repository.getAccounts()]
      ..sort((left, right) => TurkishText.compare(left.name, right.name));
    return List.unmodifiable(accounts);
  }
}
