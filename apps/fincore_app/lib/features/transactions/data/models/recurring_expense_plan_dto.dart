import 'package:fincore_app/features/transactions/domain/entities/recurring_expense_plan.dart';

final class RecurringExpensePlanDto {
  const RecurringExpensePlanDto(this.plan);

  factory RecurringExpensePlanDto.fromJson(Map<String, Object?> json) {
    return RecurringExpensePlanDto(
      RecurringExpensePlan(
        id: json['id']! as String,
        accountId: json['accountId'] as String?,
        creditCardId: json['creditCardId'] as String?,
        customerId: json['customerId'] as String?,
        amount: (json['amount']! as num).toDouble(),
        description: json['description']! as String,
        categoryId: json['categoryId'] as String?,
        currencyCode: json['currencyCode']! as String,
        firstDueDate: DateTime.parse(json['firstDueDate']! as String),
        occurrenceCount: json['occurrenceCount']! as int,
      ),
    );
  }

  final RecurringExpensePlan plan;

  Map<String, Object?> toJson() {
    return {
      'id': plan.id,
      'accountId': plan.accountId,
      'creditCardId': plan.creditCardId,
      'customerId': plan.customerId,
      'amount': plan.amount,
      'description': plan.description,
      'categoryId': plan.categoryId,
      'currencyCode': plan.currencyCode,
      'firstDueDate': plan.firstDueDate.toIso8601String(),
      'occurrenceCount': plan.occurrenceCount,
    };
  }
}
