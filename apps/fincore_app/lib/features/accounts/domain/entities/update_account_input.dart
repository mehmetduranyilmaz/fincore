import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';

final class UpdateAccountInput {
  const UpdateAccountInput({
    required this.accountId,
    required this.name,
    required this.type,
    required this.currencyCode,
    required this.openingBalance,
    this.bankId,
    this.iban,
  });

  final String accountId;
  final String name;
  final AccountType type;
  final String currencyCode;
  final double openingBalance;
  final String? bankId;
  final String? iban;
}
