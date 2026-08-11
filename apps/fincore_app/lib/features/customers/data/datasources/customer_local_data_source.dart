import 'dart:convert';

import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/customers/data/models/customer_dto.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';

abstract interface class CustomerDataSource {
  Future<List<Customer>> getCustomers();

  Future<Customer?> findById(String customerId);

  Future<void> insert(Customer customer);

  Future<void> replace(Customer customer);

  Future<void> archive(String customerId);
}

final class CustomerLocalDataSource implements CustomerDataSource {
  const CustomerLocalDataSource(this._storage);

  static const String _storageKey = 'customers_v1';
  final SecureStorageService _storage;

  @override
  Future<List<Customer>> getCustomers() async {
    return List.unmodifiable(
      (await _readAll()).where((customer) => !customer.isArchived),
    );
  }

  @override
  Future<Customer?> findById(String customerId) async {
    for (final customer in await _readAll()) {
      if (customer.id == customerId && !customer.isArchived) {
        return customer;
      }
    }
    return null;
  }

  @override
  Future<void> insert(Customer customer) async {
    final customers = await _readAll();
    if (customers.any((item) => item.id == customer.id)) {
      throw StateError('Customer already exists.');
    }
    await _writeAll([customer, ...customers]);
  }

  @override
  Future<void> replace(Customer customer) async {
    final customers = await _readAll();
    final index = customers.indexWhere((item) => item.id == customer.id);
    if (index < 0 || customers[index].isArchived) {
      throw StateError('Customer not found.');
    }
    customers[index] = customer;
    await _writeAll(customers);
  }

  @override
  Future<void> archive(String customerId) async {
    final customers = await _readAll();
    final index = customers.indexWhere((item) => item.id == customerId);
    if (index < 0 || customers[index].isArchived) {
      throw StateError('Customer not found.');
    }
    customers[index] = customers[index].copyWith(isArchived: true);
    await _writeAll(customers);
  }

  Future<List<Customer>> _readAll() async {
    final value = await _storage.read(key: _storageKey);
    if (value == null || value.isEmpty) {
      await _writeAll(const []);
      return [];
    }
    final json = jsonDecode(value);
    if (json is! List<Object?>) {
      throw const FormatException('Invalid customer storage.');
    }
    return [
      for (final item in json)
        CustomerDto.fromJson(item! as Map<String, Object?>).customer,
    ];
  }

  Future<void> _writeAll(List<Customer> customers) {
    return _storage.write(
      key: _storageKey,
      value: jsonEncode([
        for (final customer in customers) CustomerDto(customer).toJson(),
      ]),
    );
  }
}
