import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class CalculateCustomerBalanceUseCase {
  const CalculateCustomerBalanceUseCase(
    this._customerRepository,
    this._transactionRepository,
  );

  final CustomerRepository _customerRepository;
  final TransactionRepository _transactionRepository;

  Future<double> execute(String customerId) async {
    final customer = await _customerRepository.getById(customerId);
    if (customer == null) {
      throw StateError('Customer not found.');
    }
    final transactions = await _transactionRepository.getTransactions(
      TransactionFilter(),
    );
    return transactions
        .where((item) => !item.isDeleted && item.customerId == customerId)
        .fold<double>(
          customer.openingBalance,
          (balance, item) => balance + item.customerBalanceDelta!,
        );
  }
}
