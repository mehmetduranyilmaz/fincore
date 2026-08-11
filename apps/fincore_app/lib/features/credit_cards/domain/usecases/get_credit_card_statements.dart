import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_statement_repository.dart';

final class GetCreditCardStatementsUseCase {
  const GetCreditCardStatementsUseCase(this._repository);

  final CreditCardStatementRepository _repository;

  Future<List<CreditCardStatement>> execute(String creditCardId) async {
    if (creditCardId.trim().isEmpty) {
      throw ArgumentError.value(creditCardId, 'creditCardId');
    }
    final statements = await _repository.getByCreditCardId(creditCardId);
    return [
      ...statements,
    ]..sort((left, right) => right.statementDate.compareTo(left.statementDate));
  }
}
