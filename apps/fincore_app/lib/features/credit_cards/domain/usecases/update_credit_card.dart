import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/errors/credit_card_operation_exception.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_command_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/credit_card_validator.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';

final class UpdateCreditCardInput {
  const UpdateCreditCardInput({
    required this.id,
    required this.bankName,
    required this.cardName,
    required this.lastFourDigits,
    required this.creditLimit,
    required this.statementDay,
    required this.dueDay,
    required this.currencyCode,
    required this.isArchived,
  });

  final String id;
  final String bankName;
  final String cardName;
  final String lastFourDigits;
  final double creditLimit;
  final int statementDay;
  final int dueDay;
  final String currencyCode;
  final bool isArchived;
}

final class UpdateCreditCardUseCase {
  const UpdateCreditCardUseCase(this._repository, {this.lookupRepository});

  final CreditCardCommandRepository _repository;
  final CreditCardRepository? lookupRepository;

  Future<CreditCard> execute(UpdateCreditCardInput input) async {
    final existing = await _repository.getById(input.id);
    if (existing == null) {
      throw StateError('Credit card not found.');
    }

    CreditCardValidator.validateCreditLimit(input.creditLimit);
    CreditCardValidator.validateDay(input.statementDay, 'statementDay');
    CreditCardValidator.validateDay(input.dueDay, 'dueDay');

    final creditCard = existing.copyWith(
      bankName: CreditCardValidator.validateRequiredText(
        input.bankName,
        argumentName: 'bankName',
        maxLength: 100,
      ),
      cardName: CreditCardValidator.validateRequiredText(
        input.cardName,
        argumentName: 'cardName',
        maxLength: 80,
      ),
      lastFourDigits: CreditCardValidator.validateLastFourDigits(
        input.lastFourDigits,
      ),
      creditLimit: input.creditLimit,
      statementDay: input.statementDay,
      dueDay: input.dueDay,
      currencyCode: CreditCardValidator.validateCurrencyCode(
        input.currencyCode,
      ),
      isArchived: input.isArchived,
    );

    final cards = await lookupRepository?.getCreditCards() ?? const [];
    if (cards.any(
      (item) =>
          item.id != existing.id &&
          item.lastFourDigits == creditCard.lastFourDigits &&
          TurkishText.normalize(item.bankName) ==
              TurkishText.normalize(creditCard.bankName),
    )) {
      throw const CreditCardOperationException(
        'Bu bankaya ait son dört hanesi aynı olan kart zaten kayıtlı.',
      );
    }

    await _repository.update(creditCard);
    return creditCard;
  }
}
