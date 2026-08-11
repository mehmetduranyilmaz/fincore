import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';

abstract interface class CreditCardCommandRepository {
  Future<CreditCard?> getById(String creditCardId);

  Future<void> create(CreditCard creditCard);

  Future<void> update(CreditCard creditCard);

  Future<void> delete(String creditCardId);
}
