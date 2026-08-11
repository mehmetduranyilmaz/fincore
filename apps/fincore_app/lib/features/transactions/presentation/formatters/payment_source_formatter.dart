import 'package:fincore_app/core/banking/turkish_bank.dart';
import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';

abstract final class PaymentSourceFormatter {
  static String account(Account account) {
    final currency = _currency(account.currencyCode);
    if (account.type == AccountType.cash) {
      return 'KS-$currency';
    }

    final bank = TurkishBanks.findById(account.bankId);
    final bankCode = bank?.badge.toUpperCase() ?? 'BNK';
    return 'BK-$bankCode-$currency';
  }

  static String creditCard(CreditCard creditCard) {
    final bank = TurkishBanks.findByName(creditCard.bankName);
    final bankName = (bank?.name ?? creditCard.bankName).trim().toUpperCase();
    return 'KK-$bankName-${creditCard.lastFourDigits}';
  }

  static String _currency(String currencyCode) {
    final normalized = currencyCode.trim().toUpperCase();
    return normalized == 'TRY' ? 'TL' : normalized;
  }
}
