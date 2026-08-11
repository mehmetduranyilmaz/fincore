import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';

abstract interface class CreditCardStatementRepository {
  Future<List<CreditCardStatement>> getByCreditCardId(String creditCardId);

  Future<void> create(CreditCardStatement statement);
}
