import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_mock_data_source.dart';
import 'package:fincore_app/features/credit_cards/data/repositories/credit_card_repository_impl.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../credit_cards_test_data.dart';

void main() {
  test('returns an immutable credit card list from the data source', () async {
    final creditCards = createCreditCards();
    final dataSource = _CreditCardDataSource(creditCards);
    final repository = CreditCardRepositoryImpl(dataSource);

    final result = await repository.getCreditCards();

    expect(result, creditCards);
    expect(dataSource.callCount, 1);
    expect(() => result.add(creditCards.first), throwsUnsupportedError);
  });

  test('mock data contains four different credit cards', () async {
    final creditCards = await const CreditCardMockDataSource().getCreditCards();

    expect(creditCards, hasLength(4));
    expect(
      creditCards.map((creditCard) => creditCard.bankName).toSet(),
      hasLength(4),
    );
  });
}

final class _CreditCardDataSource implements CreditCardDataSource {
  _CreditCardDataSource(this.creditCards);

  final List<CreditCard> creditCards;
  int callCount = 0;

  @override
  Future<List<CreditCard>> getCreditCards() async {
    callCount++;
    return creditCards;
  }
}
