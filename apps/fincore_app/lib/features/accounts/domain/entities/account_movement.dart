import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';

final class AccountMovement {
  const AccountMovement({
    required this.transaction,
    required this.balanceAfterMovement,
  });

  final Transaction transaction;
  final double balanceAfterMovement;
}
