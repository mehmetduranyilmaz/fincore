import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/usecases/get_customers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CustomersStatus { initial, loading, loaded, failure }

final class CustomersState {
  const CustomersState._({
    required this.status,
    this.customers = const [],
    this.errorMessage,
  });
  const CustomersState.initial() : this._(status: CustomersStatus.initial);
  const CustomersState.loading() : this._(status: CustomersStatus.loading);
  CustomersState.loaded(List<Customer> customers)
    : this._(
        status: CustomersStatus.loaded,
        customers: List.unmodifiable(customers),
      );
  const CustomersState.failure(String message)
    : this._(status: CustomersStatus.failure, errorMessage: message);

  final CustomersStatus status;
  final List<Customer> customers;
  final String? errorMessage;
}

final customersControllerProvider =
    NotifierProvider<CustomersController, CustomersState>(
      CustomersController.new,
    );

final class CustomersController extends Notifier<CustomersState> {
  late GetCustomersUseCase _getCustomers;

  @override
  CustomersState build() {
    _getCustomers = ref.watch(getCustomersProvider);
    return const CustomersState.initial();
  }

  Future<void> load() async {
    state = const CustomersState.loading();
    try {
      state = CustomersState.loaded(await _getCustomers.execute());
    } on Object catch (error) {
      state = CustomersState.failure(ErrorMapper.map(error));
    }
  }
}
