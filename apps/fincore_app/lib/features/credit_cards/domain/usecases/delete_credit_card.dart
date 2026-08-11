import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_command_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/errors/credit_card_operation_exception.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_usage_repository.dart';

final class DeleteCreditCardUseCase {
  const DeleteCreditCardUseCase(this._repository, this._usageRepository);

  final CreditCardCommandRepository _repository;
  final CreditCardUsageRepository _usageRepository;

  Future<void> execute(String creditCardId) async {
    if (creditCardId.trim().isEmpty) {
      throw ArgumentError.value(creditCardId, 'creditCardId');
    }
    if (await _usageRepository.hasUsage(creditCardId)) {
      throw const CreditCardOperationException(
        'Hareket görmüş kredi kartı silinemez. Kartı arşivleyebilirsiniz.',
      );
    }
    await _repository.delete(creditCardId);
  }
}
