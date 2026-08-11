import 'package:fincore_app/features/customers/domain/entities/create_customer_input.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/errors/customer_operation_exception.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';

typedef CustomerIdGenerator = String Function();

final class CreateCustomerUseCase {
  CreateCustomerUseCase(this._repository, {CustomerIdGenerator? idGenerator})
    : _idGenerator = idGenerator ?? _generateId;

  final CustomerRepository _repository;
  final CustomerIdGenerator _idGenerator;

  Future<Customer> execute(CreateCustomerInput input) async {
    if (input.name.trim().isEmpty) {
      throw ArgumentError.value(input.name, 'name');
    }
    if (!input.openingBalance.isFinite) {
      throw ArgumentError.value(input.openingBalance, 'openingBalance');
    }
    if (!const {'TRY', 'USD', 'EUR'}.contains(input.currencyCode)) {
      throw ArgumentError.value(input.currencyCode, 'currencyCode');
    }
    final name = input.name.trim();
    final customers = await _repository.getCustomers();
    if (customers.any(
      (item) => TurkishText.normalize(item.name) == TurkishText.normalize(name),
    )) {
      throw const CustomerOperationException(
        'Aynı isimde başka bir müşteri zaten var.',
      );
    }

    final customer = Customer(
      id: _idGenerator(),
      name: name,
      openingBalance: input.openingBalance,
      currencyCode: input.currencyCode,
      isArchived: false,
    );
    await _repository.create(customer);
    return customer;
  }

  static String _generateId() {
    return 'customer-${DateTime.now().microsecondsSinceEpoch}';
  }
}
