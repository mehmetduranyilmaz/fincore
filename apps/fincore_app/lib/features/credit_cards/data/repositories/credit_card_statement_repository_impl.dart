import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_statement_local_data_source.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';

final class CreditCardStatementRepositoryImpl
    implements CreditCardStatementRepository {
  const CreditCardStatementRepositoryImpl(this._dataSource);

  final CreditCardStatementDataSource _dataSource;

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(String creditCardId) {
    return _dataSource.getByCreditCardId(creditCardId);
  }

  @override
  Future<void> create(CreditCardStatement statement) {
    return _dataSource.insert(statement);
  }
}
