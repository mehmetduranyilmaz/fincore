import 'dart:math' as math;

final class CreditCardBalance {
  factory CreditCardBalance({
    required double creditLimit,
    required double currentDebt,
    double? availableLimitUsed,
    required double totalSpent,
    required double totalPayments,
  }) {
    return CreditCardBalance._(
      currentDebt: currentDebt,
      totalSpent: totalSpent,
      totalPayments: totalPayments,
      availableLimit: math
          .max(0, creditLimit - (availableLimitUsed ?? currentDebt))
          .toDouble(),
    );
  }

  const CreditCardBalance._({
    required this.currentDebt,
    required this.totalSpent,
    required this.totalPayments,
    required this.availableLimit,
  });

  final double currentDebt;
  final double totalSpent;
  final double totalPayments;
  final double availableLimit;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CreditCardBalance &&
            currentDebt == other.currentDebt &&
            totalSpent == other.totalSpent &&
            totalPayments == other.totalPayments &&
            availableLimit == other.availableLimit;
  }

  @override
  int get hashCode {
    return Object.hash(currentDebt, totalSpent, totalPayments, availableLimit);
  }
}
