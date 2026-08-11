import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/errors/credit_card_operation_exception.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_command_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/credit_card_validator.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';

typedef CreditCardIdGenerator = String Function();

final class CreateCreditCardInput {
  const CreateCreditCardInput({
    required this.bankName,
    required this.cardName,
    required this.lastFourDigits,
    required this.creditLimit,
    required this.statementDay,
    required this.dueDay,
    required this.currencyCode,
  });

  final String bankName;
  final String cardName;
  final String lastFourDigits;
  final double creditLimit;
  final int statementDay;
  final int dueDay;
  final String currencyCode;
}

final class CreateCreditCardUseCase {
  CreateCreditCardUseCase(
    this._repository, {
    this.lookupRepository,
    CreditCardIdGenerator? idGenerator,
  }) : _idGenerator =
           idGenerator ??
           (() => 'credit-card-${DateTime.now().microsecondsSinceEpoch}');

  final CreditCardCommandRepository _repository;
  final CreditCardRepository? lookupRepository;
  final CreditCardIdGenerator _idGenerator;

  Future<CreditCard> execute(CreateCreditCardInput input) async {
    final creditCard = CreditCard(
      id: _idGenerator(),
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
      isArchived: false,
    );

    CreditCardValidator.validateCreditLimit(creditCard.creditLimit);
    CreditCardValidator.validateDay(creditCard.statementDay, 'statementDay');
    CreditCardValidator.validateDay(creditCard.dueDay, 'dueDay');

    final cards = await lookupRepository?.getCreditCards() ?? const [];
    if (cards.any(
      (item) =>
          item.lastFourDigits == creditCard.lastFourDigits &&
          TurkishText.normalize(item.bankName) ==
              TurkishText.normalize(creditCard.bankName),
    )) {
      throw const CreditCardOperationException(
        'Bu bankaya ait son dört hanesi aynı olan kart zaten kayıtlı.',
      );
    }

    await _repository.create(creditCard);
    return creditCard;
  }
}
