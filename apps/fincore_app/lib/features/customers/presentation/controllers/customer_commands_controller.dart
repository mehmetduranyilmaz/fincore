import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/customers/domain/entities/create_customer_input.dart';
import 'package:fincore_app/features/customers/domain/entities/credit_card_payment_input.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_payment_input.dart';
import 'package:fincore_app/features/customers/domain/entities/update_customer_input.dart';
import 'package:fincore_app/features/customers/domain/entities/update_customer_payment_input.dart';
import 'package:fincore_app/features/customers/domain/errors/customer_operation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CustomerCommandStatus { initial, loading, success, failure }

final class CustomerCommandState {
  const CustomerCommandState._({required this.status, this.errorMessage});
  const CustomerCommandState.initial()
    : this._(status: CustomerCommandStatus.initial);
  const CustomerCommandState.loading()
    : this._(status: CustomerCommandStatus.loading);
  const CustomerCommandState.success()
    : this._(status: CustomerCommandStatus.success);
  const CustomerCommandState.failure(String message)
    : this._(status: CustomerCommandStatus.failure, errorMessage: message);

  final CustomerCommandStatus status;
  final String? errorMessage;
}

final customerCommandsControllerProvider =
    NotifierProvider<CustomerCommandsController, CustomerCommandState>(
      CustomerCommandsController.new,
    );

final class CustomerCommandsController extends Notifier<CustomerCommandState> {
  @override
  CustomerCommandState build() => const CustomerCommandState.initial();

  Future<bool> createCustomer(CreateCustomerInput input) async {
    return _execute(() async {
      final customer = await ref.read(createCustomerProvider).execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .customerChanged(customer.id);
    });
  }

  Future<bool> createCustomerPayment(CustomerPaymentInput input) async {
    return _execute(() async {
      final transaction = await ref
          .read(createCustomerPaymentProvider)
          .execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: [transaction]);
    });
  }

  Future<bool> updateCustomer(UpdateCustomerInput input) async {
    return _execute(() async {
      final customer = await ref.read(updateCustomerProvider).execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .customerChanged(customer.id);
    });
  }

  Future<bool> updateCustomerPayment(UpdateCustomerPaymentInput input) async {
    return _execute(() async {
      final previous = await ref
          .read(transactionRepositoryProvider)
          .getById(input.transactionId);
      final transaction = await ref
          .read(updateCustomerPaymentProvider)
          .execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: [transaction], previous: [?previous]);
    });
  }

  Future<bool> deleteCustomer(String customerId) async {
    return _execute(() async {
      await ref.read(deleteCustomerProvider).execute(customerId);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .customerChanged(customerId);
    });
  }

  Future<bool> createCreditCardPayment(CreditCardPaymentInput input) async {
    return _execute(() async {
      final transactions = await ref
          .read(createCreditCardPaymentProvider)
          .execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: transactions);
    });
  }

  Future<bool> _execute(Future<void> Function() action) async {
    state = const CustomerCommandState.loading();
    try {
      await action();
      state = const CustomerCommandState.success();
      return true;
    } on CustomerOperationException catch (error) {
      state = CustomerCommandState.failure(error.message);
      return false;
    } on Object catch (error) {
      state = CustomerCommandState.failure(ErrorMapper.map(error));
      return false;
    }
  }

  void reset() => state = const CustomerCommandState.initial();
}
