final class UpdateCustomerInput {
  const UpdateCustomerInput({
    required this.customerId,
    required this.name,
    required this.openingBalance,
    required this.currencyCode,
  });

  final String customerId;
  final String name;
  final double openingBalance;
  final String currencyCode;
}
