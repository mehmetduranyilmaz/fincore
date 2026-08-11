import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_mock_data_source.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';

final class CreditCardRepositoryImpl implements CreditCardRepository {
  const CreditCardRepositoryImpl(this._dataSource);

  final CreditCardDataSource _dataSource;

  @override
  Future<List<CreditCard>> getCreditCards() async {
    final creditCards = await _dataSource.getCreditCards();
    return List.unmodifiable(creditCards);
  }
}
