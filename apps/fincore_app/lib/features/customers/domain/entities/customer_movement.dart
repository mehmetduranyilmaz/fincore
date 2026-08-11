import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';

enum CustomerBalanceSide { debtor, creditor, settled }

final class CustomerMovement {
  const CustomerMovement({
    required this.transaction,
    required this.balanceAfterMovement,
  });

  final Transaction transaction;

  /// Customer perspective: positive means the customer owes us.
  final double balanceAfterMovement;

  CustomerBalanceSide get balanceSide {
    if (balanceAfterMovement > 0) return CustomerBalanceSide.debtor;
    if (balanceAfterMovement < 0) return CustomerBalanceSide.creditor;
    return CustomerBalanceSide.settled;
  }
}
