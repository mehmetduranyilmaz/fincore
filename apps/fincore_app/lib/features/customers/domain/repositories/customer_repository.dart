import 'package:fincore_app/features/customers/domain/entities/customer.dart';

abstract interface class CustomerRepository {
  Future<List<Customer>> getCustomers();

  Future<Customer?> getById(String customerId);

  Future<void> create(Customer customer);

  Future<void> update(Customer customer);

  Future<void> archive(String customerId);
}
