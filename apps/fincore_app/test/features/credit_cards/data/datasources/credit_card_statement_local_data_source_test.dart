import 'package:fincore_app/core/storage/secure_storage_service.dart';
import 'package:fincore_app/features/credit_cards/data/datasources/credit_card_statement_local_data_source.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('persists immutable statement snapshots', () async {
    final storage = SecureStorageService(const FlutterSecureStorage());
    await CreditCardStatementLocalDataSource(storage).insert(_statement);

    final persisted = await CreditCardStatementLocalDataSource(
      storage,
    ).getByCreditCardId(_statement.creditCardId);

    expect(persisted, [_statement]);
    expect(persisted.single.totalAmount, 125.50);
  });

  test('rejects assigning one transaction twice', () async {
    final dataSource = CreditCardStatementLocalDataSource(
      SecureStorageService(const FlutterSecureStorage()),
    );
    await dataSource.insert(_statement);

    expect(
      () => dataSource.insert(
        CreditCardStatement(
          id: 'statement-2',
          creditCardId: 'card-1',
          statementDate: DateTime(2026, 9, 5),
          dueDate: DateTime(2026, 9, 15),
          createdAt: DateTime(2026, 9, 5),
          lines: _statement.lines,
        ),
      ),
      throwsStateError,
    );
  });
}

final _statement = CreditCardStatement(
  id: 'statement-1',
  creditCardId: 'card-1',
  statementDate: DateTime(2026, 8, 5),
  dueDate: DateTime(2026, 8, 15),
  createdAt: DateTime(2026, 8, 5),
  lines: [
    CreditCardStatementLine(
      transactionId: 'transaction-1',
      description: 'Market',
      transactionDate: DateTime(2026, 8, 4),
      amount: 125.50,
    ),
  ],
);
