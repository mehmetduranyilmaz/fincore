import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_statement_local_data_source.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_usage_repository.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';

final class CreditCardUsageRepositoryImpl implements CreditCardUsageRepository {
  const CreditCardUsageRepositoryImpl(
    this._transactionDataSource,
    this._statementDataSource,
  );

  final TransactionDataSource _transactionDataSource;
  final CreditCardStatementDataSource _statementDataSource;

  @override
  Future<bool> hasUsage(String creditCardId) async {
    if (await _transactionDataSource.hasAnyCreditCardMovement(creditCardId)) {
      return true;
    }
    return (await _statementDataSource.getByCreditCardId(
      creditCardId,
    )).isNotEmpty;
  }
}
