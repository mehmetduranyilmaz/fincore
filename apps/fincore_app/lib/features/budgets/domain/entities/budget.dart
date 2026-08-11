final class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
  });

  final String id;
  final String categoryId;
  final int month;
  final int year;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Budget copyWith({
    String? categoryId,
    int? month,
    int? year,
    double? amount,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Budget(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Budget &&
            id == other.id &&
            categoryId == other.categoryId &&
            month == other.month &&
            year == other.year &&
            amount == other.amount &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt &&
            isDeleted == other.isDeleted;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      categoryId,
      month,
      year,
      amount,
      createdAt,
      updatedAt,
      isDeleted,
    );
  }
}
