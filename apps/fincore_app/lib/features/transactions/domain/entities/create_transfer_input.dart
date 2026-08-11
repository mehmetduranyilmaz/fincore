final class CreateTransferInput {
  const CreateTransferInput({
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.description,
    required this.transferDate,
  });

  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final String description;
  final DateTime transferDate;
}
