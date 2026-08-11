final class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.openingBalance,
    required this.currencyCode,
    required this.isArchived,
  });

  final String id;
  final String name;

  /// Positive: customer owes us. Negative: we owe the customer.
  final double openingBalance;
  final String currencyCode;
  final bool isArchived;

  Customer copyWith({
    String? name,
    double? openingBalance,
    String? currencyCode,
    bool? isArchived,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      openingBalance: openingBalance ?? this.openingBalance,
      currencyCode: currencyCode ?? this.currencyCode,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
