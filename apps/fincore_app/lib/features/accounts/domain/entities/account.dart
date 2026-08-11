import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';

final class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.currencyCode,
    required this.isArchived,
    this.openingBalance = 0,
    this.bankId,
    this.iban,
  });

  final String id;
  final String name;
  final AccountType type;
  final String currencyCode;
  final bool isArchived;
  final double openingBalance;
  final String? bankId;
  final String? iban;

  Account copyWith({
    String? name,
    AccountType? type,
    String? currencyCode,
    bool? isArchived,
    double? openingBalance,
    String? bankId,
    bool clearBankId = false,
    String? iban,
    bool clearIban = false,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      currencyCode: currencyCode ?? this.currencyCode,
      isArchived: isArchived ?? this.isArchived,
      openingBalance: openingBalance ?? this.openingBalance,
      bankId: clearBankId ? null : bankId ?? this.bankId,
      iban: clearIban ? null : iban ?? this.iban,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Account &&
            id == other.id &&
            name == other.name &&
            type == other.type &&
            currencyCode == other.currencyCode &&
            isArchived == other.isArchived &&
            openingBalance == other.openingBalance &&
            bankId == other.bankId &&
            iban == other.iban;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      type,
      currencyCode,
      isArchived,
      openingBalance,
      bankId,
      iban,
    );
  }
}
