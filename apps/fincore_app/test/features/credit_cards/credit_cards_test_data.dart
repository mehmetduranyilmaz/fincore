import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';

List<CreditCard> createCreditCards() {
  return const [
    CreditCard(
      id: 'credit-card-1',
      bankName: 'Test Bank',
      cardName: 'Test Card',
      lastFourDigits: '1111',
      creditLimit: 10000,
      statementDay: 10,
      dueDay: 20,
      currencyCode: 'TRY',
      isArchived: false,
    ),
    CreditCard(
      id: 'credit-card-2',
      bankName: 'Second Bank',
      cardName: 'Second Card',
      lastFourDigits: '2222',
      creditLimit: 20000,
      statementDay: 15,
      dueDay: 25,
      currencyCode: 'TRY',
      isArchived: false,
    ),
  ];
}
