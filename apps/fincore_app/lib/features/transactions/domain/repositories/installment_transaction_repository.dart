import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';

abstract interface class InstallmentTransactionRepository {
  Future<void> createPlan(List<Transaction> installments);

  Future<void> replaceWithPlan(List<Transaction> installments);
}
