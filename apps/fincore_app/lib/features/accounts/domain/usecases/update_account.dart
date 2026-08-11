import 'package:fincore_app/core/utils/turkish_text.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/core/banking/turkish_bank.dart';
import 'package:fincore_app/features/accounts/domain/entities/update_account_input.dart';
import 'package:fincore_app/features/accounts/domain/errors/account_operation_exception.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_command_repository.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/domain/value_objects/turkish_iban.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class UpdateAccountUseCase {
  const UpdateAccountUseCase(
    this._commandRepository,
    this._queryRepository,
    this._transactions,
  );

  final AccountCommandRepository _commandRepository;
  final AccountRepository _queryRepository;
  final TransactionRepository _transactions;

  Future<Account> execute(UpdateAccountInput input) async {
    final existing = await _commandRepository.getById(input.accountId);
    if (existing == null) {
      throw const AccountOperationException('Hesap bulunamadı.');
    }
    final name = input.name.trim();
    if (name.isEmpty || !input.openingBalance.isFinite) {
      throw ArgumentError('Invalid account values.');
    }
    final accounts = await _queryRepository.getAccounts();
    if (accounts.any(
      (item) =>
          item.id != existing.id &&
          TurkishText.normalize(item.name) == TurkishText.normalize(name),
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
              item.id != existing.id &&
              item.iban != null &&
              TurkishIban.normalize(item.iban!) == iban,
        )) {
      throw const AccountOperationException('Bu IBAN zaten kayıtlı.');
    }
    final transactions = await _transactions.getTransactions(
      TransactionFilter(accountId: existing.id),
    );
    final structuralChange =
        existing.type != input.type ||
        existing.currencyCode != input.currencyCode ||
        (existing.openingBalance * 100).round() !=
            (input.openingBalance * 100).round();
    if (transactions.isNotEmpty && structuralChange) {
      throw const AccountOperationException(
        'Hareketi bulunan hesabın türü, para birimi veya başlangıç bakiyesi değiştirilemez.',
      );
    }
    final updated = existing.copyWith(
      name: name,
      type: input.type,
      currencyCode: input.currencyCode,
      openingBalance: input.openingBalance,
      bankId: bankId,
      clearBankId: bankId == null,
      iban: iban,
      clearIban: iban == null,
    );
    await _commandRepository.update(updated);
    return updated;
  }
}
