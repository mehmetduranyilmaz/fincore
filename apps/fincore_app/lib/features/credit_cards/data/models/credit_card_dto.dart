import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';

final class CreditCardDto {
  const CreditCardDto({
    required this.id,
    required this.bankName,
    required this.cardName,
    required this.lastFourDigits,
    required this.creditLimit,
    required this.statementDay,
    required this.dueDay,
    required this.currencyCode,
    required this.isArchived,
  });

  factory CreditCardDto.fromDomain(CreditCard creditCard) {
    return CreditCardDto(
      id: creditCard.id,
      bankName: creditCard.bankName,
      cardName: creditCard.cardName,
      lastFourDigits: creditCard.lastFourDigits,
      creditLimit: creditCard.creditLimit,
      statementDay: creditCard.statementDay,
      dueDay: creditCard.dueDay,
      currencyCode: creditCard.currencyCode,
      isArchived: creditCard.isArchived,
    );
  }

  factory CreditCardDto.fromJson(Map<String, Object?> json) {
    return CreditCardDto(
      id: json['id']! as String,
      bankName: json['bankName']! as String,
      cardName: json['cardName']! as String,
      lastFourDigits: json['lastFourDigits']! as String,
      creditLimit: (json['creditLimit']! as num).toDouble(),
      statementDay: json['statementDay']! as int,
      dueDay: json['dueDay']! as int,
      currencyCode: json['currencyCode']! as String,
      isArchived: json['isArchived']! as bool,
    );
  }

  final String id;
  final String bankName;
  final String cardName;
  final String lastFourDigits;
  final double creditLimit;
  final int statementDay;
  final int dueDay;
  final String currencyCode;
  final bool isArchived;

  CreditCard toDomain() {
    return CreditCard(
      id: id,
      bankName: bankName,
      cardName: cardName,
      lastFourDigits: lastFourDigits,
      creditLimit: creditLimit,
      statementDay: statementDay,
      dueDay: dueDay,
      currencyCode: currencyCode,
      isArchived: isArchived,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'cardName': cardName,
      'lastFourDigits': lastFourDigits,
      'creditLimit': creditLimit,
      'statementDay': statementDay,
      'dueDay': dueDay,
      'currencyCode': currencyCode,
      'isArchived': isArchived,
    };
  }
}
