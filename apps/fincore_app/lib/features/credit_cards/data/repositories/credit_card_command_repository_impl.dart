import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_mock_data_source.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_command_repository.dart';

final class CreditCardCommandRepositoryImpl
    implements CreditCardCommandRepository {
  const CreditCardCommandRepositoryImpl(this._dataSource);

  final CreditCardCommandDataSource _dataSource;

  @override
  Future<CreditCard?> getById(String creditCardId) {
    return _dataSource.getById(creditCardId);
  }

  @override
  Future<void> create(CreditCard creditCard) {
    return _dataSource.insert(creditCard);
  }

  @override
  Future<void> update(CreditCard creditCard) {
    return _dataSource.replace(creditCard);
  }

  @override
  Future<void> delete(String creditCardId) {
    return _dataSource.remove(creditCardId);
  }
}
