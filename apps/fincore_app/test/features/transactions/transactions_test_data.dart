import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';

List<Transaction> createTransactions() {
  return [
    Transaction(
      id: 'transaction-1',
      accountId: 'account-1',
      creditCardId: null,
      amount: 250,
      transactionType: TransactionType.expense,
      categoryId: 'category-1',
      merchant: 'Test Market',
      note: null,
      transactionDate: DateTime(2026, 7, 25),
      source: TransactionSource.manual,
      isDeleted: false,
    ),
    Transaction(
      id: 'transaction-2',
      accountId: null,
      creditCardId: 'credit-card-1',
      amount: 5000,
      transactionType: TransactionType.income,
      categoryId: null,
      merchant: 'Test Income',
      note: 'Test note',
      transactionDate: DateTime(2026, 7, 24),
      source: TransactionSource.import,
      isDeleted: false,
    ),
  ];
}
