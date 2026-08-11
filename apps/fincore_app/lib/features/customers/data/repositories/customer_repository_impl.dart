import 'package:fincore_app/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';

final class CustomerRepositoryImpl implements CustomerRepository {
  const CustomerRepositoryImpl(this._dataSource);

  final CustomerDataSource _dataSource;

  @override
  Future<void> create(Customer customer) => _dataSource.insert(customer);

  @override
  Future<Customer?> getById(String customerId) =>
      _dataSource.findById(customerId);

  @override
  Future<List<Customer>> getCustomers() => _dataSource.getCustomers();

  @override
  Future<void> update(Customer customer) => _dataSource.replace(customer);

  @override
  Future<void> archive(String customerId) => _dataSource.archive(customerId);
}
