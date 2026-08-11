import 'package:fincore_app/core/utils/turkish_text.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/create_account_input.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/core/banking/turkish_bank.dart';
import 'package:fincore_app/features/accounts/domain/errors/account_operation_exception.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_command_repository.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/domain/value_objects/turkish_iban.dart';

typedef AccountIdGenerator = String Function();

final class CreateAccountUseCase {
  CreateAccountUseCase(
    this._commandRepository,
    this._queryRepository, {
    AccountIdGenerator? idGenerator,
  }) : _idGenerator = idGenerator ?? _generateId;

  final AccountCommandRepository _commandRepository;
  final AccountRepository _queryRepository;
  final AccountIdGenerator _idGenerator;

  Future<Account> execute(CreateAccountInput input) async {
    final name = input.name.trim();
    if (name.isEmpty || name.length > 100) {
      throw ArgumentError.value(input.name, 'name');
    }
    if (!input.openingBalance.isFinite) {
      throw ArgumentError.value(input.openingBalance, 'openingBalance');
    }
    if (!const {'TRY', 'USD', 'EUR'}.contains(input.currencyCode)) {
      throw ArgumentError.value(input.currencyCode, 'currencyCode');
    }
    final accounts = await _queryRepository.getAccounts();
    if (accounts.any(
      (item) => TurkishText.normalize(item.name) == TurkishText.normalize(name),
    )) {
      throw const AccountOperationException(
        'Aynı isimde başka bir hesap zaten var.',
      );
    }
    final bankId = input.type == AccountType.cash ? null : input.bankId;
    if (input.type != AccountType.cash &&
        TurkishBanks.findById(bankId) == null) {
      throw const AccountOperationException('Bir banka seçmelisiniz.');
    }
    final rawIban = input.type == AccountType.cash ? null : input.iban?.trim();
    final iban = rawIban == null || rawIban.isEmpty
        ? null
        : TurkishIban.normalize(rawIban);
    if (iban != null && !TurkishIban.isValid(iban)) {
      throw const AccountOperationException(
        'Geçerli bir Türkiye IBAN’ı girin.',
      );
    }
    if (iban != null &&
        accounts.any(
          (item) =>
              item.iban != null && TurkishIban.normalize(item.iban!) == iban,
        )) {
      throw const AccountOperationException('Bu IBAN zaten kayıtlı.');
    }
    final account = Account(
      id: _idGenerator(),
      name: name,
      type: input.type,
      currencyCode: input.currencyCode,
      isArchived: false,
      openingBalance: input.openingBalance,
      bankId: bankId,
      iban: iban,
    );
    await _commandRepository.create(account);
    return account;
  }

  static String _generateId() =>
      'account-${DateTime.now().microsecondsSinceEpoch}';
}
