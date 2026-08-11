import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/entities/update_customer_input.dart';
import 'package:fincore_app/features/customers/domain/errors/customer_operation_exception.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';

final class UpdateCustomerUseCase {
  const UpdateCustomerUseCase(this._customerRepository, this._transactions);

  final CustomerRepository _customerRepository;
  final TransactionRepository _transactions;

  Future<Customer> execute(UpdateCustomerInput input) async {
    if (input.customerId.trim().isEmpty || input.name.trim().isEmpty) {
      throw ArgumentError('Customer id and name are required.');
    }
    if (!input.openingBalance.isFinite) {
      throw ArgumentError.value(input.openingBalance, 'openingBalance');
    }
    final customer = await _customerRepository.getById(input.customerId);
    if (customer == null) {
      throw const CustomerOperationException('Müşteri bulunamadı.');
    }
    final customers = await _customerRepository.getCustomers();
    if (customers.any(
      (item) =>
          item.id != customer.id &&
          TurkishText.normalize(item.name) == TurkishText.normalize(input.name),
    )) {
      throw const CustomerOperationException(
        'Aynı isimde başka bir müşteri zaten var.',
      );
    }

    final openingBalanceChanged =
        (customer.openingBalance * 100).round() !=
        (input.openingBalance * 100).round();
    if (openingBalanceChanged) {
      final transactions = await _transactions.getTransactions(
        TransactionFilter(),
      );
      if (transactions.any((item) => item.customerId == customer.id)) {
        throw const CustomerOperationException(
          'Hareketi bulunan müşterinin başlangıç bakiyesi değiştirilemez.',
        );
      }
    }

    final updated = customer.copyWith(
      name: input.name.trim(),
      openingBalance: input.openingBalance,
      currencyCode: input.currencyCode,
    );
    await _customerRepository.update(updated);
    return updated;
  }
}
