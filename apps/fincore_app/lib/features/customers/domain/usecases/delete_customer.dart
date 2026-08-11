import 'package:fincore_app/features/customers/domain/errors/customer_operation_exception.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_usage_repository.dart';
import 'package:fincore_app/features/customers/domain/usecases/calculate_customer_balance.dart';

final class DeleteCustomerUseCase {
  const DeleteCustomerUseCase(
    this._repository,
    this._calculateBalance,
    this._usageRepository,
  );

  final CustomerRepository _repository;
  final CalculateCustomerBalanceUseCase _calculateBalance;
  final CustomerUsageRepository _usageRepository;

  Future<void> execute(String customerId) async {
    final customer = await _repository.getById(customerId);
    if (customer == null) {
      throw const CustomerOperationException('Müşteri bulunamadı.');
    }
    if (await _usageRepository.hasUsage(customerId)) {
      throw const CustomerOperationException(
        'Hareket görmüş müşteri silinemez.',
      );
    }
    final balance = await _calculateBalance.execute(customerId);
    if ((balance * 100).round() != 0) {
      throw const CustomerOperationException(
        'Açık bakiyesi bulunan müşteri silinemez. Önce bakiyeyi kapatın.',
      );
    }
    await _repository.archive(customerId);
  }
}
