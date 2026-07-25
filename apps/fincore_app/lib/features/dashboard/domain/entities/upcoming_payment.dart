final class UpcomingPayment {
  const UpcomingPayment({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UpcomingPayment &&
            id == other.id &&
            title == other.title &&
            amount == other.amount &&
            dueDate == other.dueDate;
  }

  @override
  int get hashCode => Object.hash(id, title, amount, dueDate);
}
