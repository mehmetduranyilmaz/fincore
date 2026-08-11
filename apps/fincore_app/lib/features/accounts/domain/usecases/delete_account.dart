import 'package:fincore_app/features/accounts/domain/errors/account_operation_exception.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_command_repository.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_usage_repository.dart';
import 'package:fincore_app/features/accounts/domain/usecases/calculate_account_balance.dart';

final class DeleteAccountUseCase {
  const DeleteAccountUseCase(
    this._repository,
    this._calculateBalance,
    this._usageRepository,
  );

  final AccountCommandRepository _repository;
  final CalculateAccountBalanceUseCase _calculateBalance;
  final AccountUsageRepository _usageRepository;

  Future<void> execute(String accountId) async {
    final account = await _repository.getById(accountId);
    if (account == null) {
      throw const AccountOperationException('Hesap bulunamadı.');
    }
    if (await _usageRepository.hasUsage(accountId)) {
      throw const AccountOperationException(
        'Hareket görmüş kasa veya banka hesabı silinemez.',
      );
    }
    final balance = await _calculateBalance.execute(accountId);
    if ((balance.currentBalance * 100).round() != 0) {
      throw const AccountOperationException(
        'Bakiyesi sıfır olmayan hesap silinemez.',
      );
    }
    await _repository.archive(accountId);
  }
}
