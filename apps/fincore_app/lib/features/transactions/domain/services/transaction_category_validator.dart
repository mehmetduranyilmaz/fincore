import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';

abstract interface class TransactionCategoryValidator {
  Future<void> validate({
    required String categoryId,
    required TransactionType transactionType,
  });
}
