import 'package:fincore_app/features/budgets/domain/entities/budget.dart';

final class BudgetDto {
  const BudgetDto(this.budget);

  factory BudgetDto.fromJson(Map<String, Object?> json) {
    return BudgetDto(
      Budget(
        id: json['id']! as String,
        categoryId: json['categoryId']! as String,
        month: json['month']! as int,
        year: json['year']! as int,
        amount: (json['amount']! as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt']! as String),
        updatedAt: DateTime.parse(json['updatedAt']! as String),
        isDeleted: json['isDeleted']! as bool,
      ),
    );
  }

  final Budget budget;

  Map<String, Object?> toJson() => {
    'id': budget.id,
    'categoryId': budget.categoryId,
    'month': budget.month,
    'year': budget.year,
    'amount': budget.amount,
    'createdAt': budget.createdAt.toIso8601String(),
    'updatedAt': budget.updatedAt.toIso8601String(),
    'isDeleted': budget.isDeleted,
  };
}
