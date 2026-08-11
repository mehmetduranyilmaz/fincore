import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_statement_local_data_source.dart';
import 'package:fincore_app/features/credit_cards/data/repositories/credit_card_usage_repository_impl.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/transactions/data/datasources/transaction_mock_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports statement-only cards as used', () async {
    final repository = CreditCardUsageRepositoryImpl(
      TransactionMockDataSource(initialTransactions: const []),
      _StatementDataSource([_statement]),
    );

    expect(await repository.hasUsage('card-1'), isTrue);
    expect(await repository.hasUsage('card-2'), isFalse);
  });
}

final class _StatementDataSource implements CreditCardStatementDataSource {
  _StatementDataSource(this.items);

  final List<CreditCardStatement> items;

  @override
  Future<List<CreditCardStatement>> getByCreditCardId(
    String creditCardId,
  ) async {
    return items.where((item) => item.creditCardId == creditCardId).toList();
  }

  @override
  Future<void> insert(CreditCardStatement statement) async {
    items.add(statement);
  }
}

final _statement = CreditCardStatement(
  id: 'statement-1',
  creditCardId: 'card-1',
  statementDate: DateTime(2026, 8, 1),
  dueDate: DateTime(2026, 8, 10),
  createdAt: DateTime(2026, 8, 1),
  lines: [
    CreditCardStatementLine(
      transactionId: 'transaction-1',
      description: 'Harcama',
      transactionDate: DateTime(2026, 7, 20),
      amount: 100,
    ),
  ],
);
