import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';

abstract interface class CreditCardDataSource {
  Future<List<CreditCard>> getCreditCards();
}

abstract interface class CreditCardCommandDataSource {
  Future<CreditCard?> getById(String creditCardId);

  Future<void> insert(CreditCard creditCard);

  Future<void> replace(CreditCard creditCard);

  Future<void> remove(String creditCardId);
}

final class CreditCardMockDataSource implements CreditCardDataSource {
  const CreditCardMockDataSource();

  @override
  Future<List<CreditCard>> getCreditCards() async {
    return List.unmodifiable(const [
      CreditCard(
        id: 'credit-card-1',
        bankName: 'Garanti BBVA',
        cardName: 'Bonus',
        lastFourDigits: '1234',
        creditLimit: 80000,
        statementDay: 12,
        dueDay: 22,
        currencyCode: 'TRY',
        isArchived: false,
      ),
      CreditCard(
        id: 'credit-card-2',
        bankName: 'İş Bankası',
        cardName: 'Maximum',
        lastFourDigits: '5678',
        creditLimit: 65000,
        statementDay: 8,
        dueDay: 18,
        currencyCode: 'TRY',
        isArchived: false,
      ),
      CreditCard(
        id: 'credit-card-3',
        bankName: 'Akbank',
        cardName: 'Axess',
        lastFourDigits: '9012',
        creditLimit: 45000,
        statementDay: 15,
        dueDay: 25,
        currencyCode: 'TRY',
        isArchived: false,
      ),
      CreditCard(
        id: 'credit-card-4',
        bankName: 'Yapı Kredi',
        cardName: 'World',
        lastFourDigits: '3456',
        creditLimit: 100000,
        statementDay: 20,
        dueDay: 30,
        currencyCode: 'TRY',
        isArchived: false,
      ),
    ]);
  }
}
