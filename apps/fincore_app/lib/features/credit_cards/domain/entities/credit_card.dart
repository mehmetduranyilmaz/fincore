final class CreditCard {
  const CreditCard({
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

  final String id;
  final String bankName;
  final String cardName;
  final String lastFourDigits;
  final double creditLimit;
  final int statementDay;
  final int dueDay;
  final String currencyCode;
  final bool isArchived;

  CreditCard copyWith({
    String? bankName,
    String? cardName,
    String? lastFourDigits,
    double? creditLimit,
    int? statementDay,
    int? dueDay,
    String? currencyCode,
    bool? isArchived,
  }) {
    return CreditCard(
      id: id,
      bankName: bankName ?? this.bankName,
      cardName: cardName ?? this.cardName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      currencyCode: currencyCode ?? this.currencyCode,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CreditCard &&
            id == other.id &&
            bankName == other.bankName &&
            cardName == other.cardName &&
            lastFourDigits == other.lastFourDigits &&
            creditLimit == other.creditLimit &&
            statementDay == other.statementDay &&
            dueDay == other.dueDay &&
            currencyCode == other.currencyCode &&
            isArchived == other.isArchived;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      bankName,
      cardName,
      lastFourDigits,
      creditLimit,
      statementDay,
      dueDay,
      currencyCode,
      isArchived,
    );
  }
}
