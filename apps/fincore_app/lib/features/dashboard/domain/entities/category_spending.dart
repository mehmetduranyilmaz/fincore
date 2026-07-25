final class CategorySpending {
  const CategorySpending({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  final String category;
  final double amount;
  final double percentage;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CategorySpending &&
            category == other.category &&
            amount == other.amount &&
            percentage == other.percentage;
  }

  @override
  int get hashCode => Object.hash(category, amount, percentage);
}
