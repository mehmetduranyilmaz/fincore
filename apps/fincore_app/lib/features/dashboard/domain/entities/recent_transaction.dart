enum TransactionType { income, expense }

final class RecentTransaction {
  const RecentTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.occurredAt,
    required this.type,
  });

  final String id;
  final String description;
  final double amount;
  final DateTime occurredAt;
  final TransactionType type;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RecentTransaction &&
            id == other.id &&
            description == other.description &&
            amount == other.amount &&
            occurredAt == other.occurredAt &&
            type == other.type;
  }

  @override
  int get hashCode => Object.hash(id, description, amount, occurredAt, type);
}
