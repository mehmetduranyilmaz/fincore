import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';

final class Transaction {
  factory Transaction({
    required String id,
    required String? accountId,
    required String? creditCardId,
    required double amount,
    required TransactionType transactionType,
    required String? categoryId,
    required String merchant,
    required String? note,
    required DateTime transactionDate,
    required TransactionSource source,
    required bool isDeleted,
    String? transferGroupId,
    String? installmentPlanId,
    int? installmentNumber,
    int? installmentCount,
    double? installmentTotalAmount,
    String? paymentGroupId,
    String? customerId,
    double? customerBalanceDelta,
  }) {
    validateSource(accountId: accountId, creditCardId: creditCardId);
    validateInstallment(
      installmentPlanId: installmentPlanId,
      installmentNumber: installmentNumber,
      installmentCount: installmentCount,
      installmentTotalAmount: installmentTotalAmount,
    );
    validateCustomerMovement(
      customerId: customerId,
      customerBalanceDelta: customerBalanceDelta,
    );

    return Transaction._(
      id: id,
      accountId: accountId,
      creditCardId: creditCardId,
      amount: amount,
      transactionType: transactionType,
      categoryId: categoryId,
      merchant: merchant,
      note: note,
      transactionDate: transactionDate,
      source: source,
      isDeleted: isDeleted,
      transferGroupId: transferGroupId,
      installmentPlanId: installmentPlanId,
      installmentNumber: installmentNumber,
      installmentCount: installmentCount,
      installmentTotalAmount: installmentTotalAmount,
      paymentGroupId: paymentGroupId,
      customerId: customerId,
      customerBalanceDelta: customerBalanceDelta,
    );
  }

  const Transaction._({
    required this.id,
    required this.accountId,
    required this.creditCardId,
    required this.amount,
    required this.transactionType,
    required this.categoryId,
    required this.merchant,
    required this.note,
    required this.transactionDate,
    required this.source,
    required this.isDeleted,
    required this.transferGroupId,
    required this.installmentPlanId,
    required this.installmentNumber,
    required this.installmentCount,
    required this.installmentTotalAmount,
    required this.paymentGroupId,
    required this.customerId,
    required this.customerBalanceDelta,
  });

  final String id;
  final String? accountId;
  final String? creditCardId;
  final double amount;
  final TransactionType transactionType;
  final String? categoryId;
  final String merchant;
  final String? note;
  final DateTime transactionDate;
  final TransactionSource source;
  final bool isDeleted;
  final String? transferGroupId;
  final String? installmentPlanId;
  final int? installmentNumber;
  final int? installmentCount;
  final double? installmentTotalAmount;
  final String? paymentGroupId;
  final String? customerId;
  final double? customerBalanceDelta;

  bool get isInstallment => installmentPlanId != null;

  bool get isCustomerPayment {
    return customerId != null &&
        customerBalanceDelta != null &&
        paymentGroupId != null &&
        source == TransactionSource.manual;
  }

  bool get canConvertToInstallments {
    return !isDeleted &&
        !isInstallment &&
        paymentGroupId == null &&
        transactionType == TransactionType.expense &&
        creditCardId != null;
  }

  bool get isEditable {
    return !isInstallment &&
        paymentGroupId == null &&
        source == TransactionSource.manual &&
        (transactionType == TransactionType.income ||
            transactionType == TransactionType.expense);
  }

  bool get isDeletable {
    return !isDeleted &&
        (source == TransactionSource.manual ||
            source == TransactionSource.receiptScan);
  }

  static void validateSource({
    required String? accountId,
    required String? creditCardId,
  }) {
    if ((accountId == null) == (creditCardId == null)) {
      throw ArgumentError(
        'Exactly one of accountId and creditCardId must be provided.',
      );
    }
  }

  static void validateInstallment({
    required String? installmentPlanId,
    required int? installmentNumber,
    required int? installmentCount,
    required double? installmentTotalAmount,
  }) {
    final values = [
      installmentPlanId,
      installmentNumber,
      installmentCount,
      installmentTotalAmount,
    ];
    final hasAnyValue = values.any((value) => value != null);
    final hasEveryValue = values.every((value) => value != null);
    if (hasAnyValue != hasEveryValue) {
      throw ArgumentError('Installment metadata must be complete.');
    }
    if (!hasAnyValue) {
      return;
    }
    if (installmentPlanId!.trim().isEmpty ||
        installmentCount! < 2 ||
        installmentNumber! < 1 ||
        installmentNumber > installmentCount ||
        !installmentTotalAmount!.isFinite ||
        installmentTotalAmount <= 0) {
      throw ArgumentError('Invalid installment metadata.');
    }
  }

  static void validateCustomerMovement({
    required String? customerId,
    required double? customerBalanceDelta,
  }) {
    if ((customerId == null) != (customerBalanceDelta == null)) {
      throw ArgumentError('Customer movement metadata must be complete.');
    }
    if (customerId != null &&
        (customerId.trim().isEmpty ||
            !customerBalanceDelta!.isFinite ||
            customerBalanceDelta == 0)) {
      throw ArgumentError('Invalid customer movement metadata.');
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Transaction &&
            id == other.id &&
            accountId == other.accountId &&
            creditCardId == other.creditCardId &&
            amount == other.amount &&
            transactionType == other.transactionType &&
            categoryId == other.categoryId &&
            merchant == other.merchant &&
            note == other.note &&
            transactionDate == other.transactionDate &&
            source == other.source &&
            isDeleted == other.isDeleted &&
            transferGroupId == other.transferGroupId &&
            installmentPlanId == other.installmentPlanId &&
            installmentNumber == other.installmentNumber &&
            installmentCount == other.installmentCount &&
            installmentTotalAmount == other.installmentTotalAmount &&
            paymentGroupId == other.paymentGroupId &&
            customerId == other.customerId &&
            customerBalanceDelta == other.customerBalanceDelta;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      accountId,
      creditCardId,
      amount,
      transactionType,
      categoryId,
      merchant,
      note,
      transactionDate,
      source,
      isDeleted,
      transferGroupId,
      installmentPlanId,
      installmentNumber,
      installmentCount,
      installmentTotalAmount,
      paymentGroupId,
      customerId,
      customerBalanceDelta,
    );
  }
}
