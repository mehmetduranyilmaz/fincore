import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';

abstract interface class CreditCardRepository {
  Future<List<CreditCard>> getCreditCards();
}
