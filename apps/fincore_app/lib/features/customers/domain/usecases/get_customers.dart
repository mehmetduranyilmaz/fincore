import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';

final class GetCustomersUseCase {
  const GetCustomersUseCase(this._repository);

  final CustomerRepository _repository;

  Future<List<Customer>> execute() async {
    final customers = [...await _repository.getCustomers()]
      ..sort((left, right) => TurkishText.compare(left.name, right.name));
    return List.unmodifiable(customers);
  }
}
