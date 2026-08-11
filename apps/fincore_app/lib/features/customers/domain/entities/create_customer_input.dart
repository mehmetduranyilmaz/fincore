final class CreateCustomerInput {
  const CreateCustomerInput({
    required this.name,
    required this.openingBalance,
    required this.currencyCode,
  });

  final String name;
  final double openingBalance;
  final String currencyCode;
}
