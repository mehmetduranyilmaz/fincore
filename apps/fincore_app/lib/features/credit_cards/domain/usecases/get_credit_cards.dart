import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/core/utils/turkish_text.dart';

final class GetCreditCards {
  const GetCreditCards(this._repository);

  final CreditCardRepository _repository;

  Future<List<CreditCard>> execute() async {
    final cards = [...await _repository.getCreditCards()]
      ..sort((left, right) {
        final bank = TurkishText.compare(left.bankName, right.bankName);
        return bank != 0
            ? bank
            : TurkishText.compare(left.cardName, right.cardName);
      });
    return List.unmodifiable(cards);
  }
}
