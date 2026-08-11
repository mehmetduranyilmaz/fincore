import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';

final class AccountDto {
  const AccountDto(this.account);

  factory AccountDto.fromJson(Map<String, Object?> json) {
    return AccountDto(
      Account(
        id: json['id']! as String,
        name: json['name']! as String,
        type: AccountType.values.byName(json['type']! as String),
        currencyCode: json['currencyCode']! as String,
        isArchived: json['isArchived']! as bool,
        openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0,
        bankId: json['bankId'] as String?,
        iban: json['iban'] as String?,
      ),
    );
  }

  final Account account;

  Map<String, Object?> toJson() => {
    'id': account.id,
    'name': account.name,
    'type': account.type.name,
    'currencyCode': account.currencyCode,
    'isArchived': account.isArchived,
    'openingBalance': account.openingBalance,
    'bankId': account.bankId,
    'iban': account.iban,
  };
}
