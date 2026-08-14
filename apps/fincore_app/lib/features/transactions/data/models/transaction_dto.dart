import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';

final class TransactionDto {
  const TransactionDto(this.transaction);

  factory TransactionDto.fromJson(Map<String, Object?> json) {
    return TransactionDto(
      Transaction(
        id: json['id']! as String,
        accountId: json['accountId'] as String?,
        creditCardId: json['creditCardId'] as String?,
        amount: (json['amount']! as num).toDouble(),
        transactionType: TransactionType.values.byName(
          json['transactionType']! as String,
        ),
        categoryId: json['categoryId'] as String?,
        merchant: json['merchant']! as String,
        note: json['note'] as String?,
        transactionDate: DateTime.parse(json['transactionDate']! as String),
        source: TransactionSource.values.byName(json['source']! as String),
        isDeleted: json['isDeleted']! as bool,
        transferGroupId: json['transferGroupId'] as String?,
        installmentPlanId: json['installmentPlanId'] as String?,
        installmentNumber: json['installmentNumber'] as int?,
        installmentCount: json['installmentCount'] as int?,
        installmentTotalAmount: (json['installmentTotalAmount'] as num?)
            ?.toDouble(),
        paymentGroupId: json['paymentGroupId'] as String?,
        creditCardStatementId: json['creditCardStatementId'] as String?,
        customerId: json['customerId'] as String?,
        customerBalanceDelta: (json['customerBalanceDelta'] as num?)
            ?.toDouble(),
      ),
    );
  }

  final Transaction transaction;

  Map<String, Object?> toJson() {
    return {
      'id': transaction.id,
      'accountId': transaction.accountId,
      'creditCardId': transaction.creditCardId,
      'amount': transaction.amount,
      'transactionType': transaction.transactionType.name,
      'categoryId': transaction.categoryId,
      'merchant': transaction.merchant,
      'note': transaction.note,
      'transactionDate': transaction.transactionDate.toIso8601String(),
      'source': transaction.source.name,
      'isDeleted': transaction.isDeleted,
      'transferGroupId': transaction.transferGroupId,
      'installmentPlanId': transaction.installmentPlanId,
      'installmentNumber': transaction.installmentNumber,
      'installmentCount': transaction.installmentCount,
      'installmentTotalAmount': transaction.installmentTotalAmount,
      'paymentGroupId': transaction.paymentGroupId,
      'creditCardStatementId': transaction.creditCardStatementId,
      'customerId': transaction.customerId,
      'customerBalanceDelta': transaction.customerBalanceDelta,
    };
  }
}
