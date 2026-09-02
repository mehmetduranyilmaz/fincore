import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_movement.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/reports/presentation/financial_report_factories.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds an account statement report from the selected date range', () {
    const account = Account(
      id: 'account-1',
      name: 'TL Kasa',
      type: AccountType.cash,
      currencyCode: 'TRY',
      openingBalance: 1000,
      isArchived: false,
    );
    final report = FinancialReportFactories.accountMovements(
      account: account,
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 31),
      movements: [
        AccountMovement(
          transaction: _transaction(
            id: 'expense',
            type: TransactionType.expense,
            amount: 250,
          ),
          balanceAfterMovement: 1750,
        ),
        AccountMovement(
          transaction: _transaction(
            id: 'income',
            type: TransactionType.income,
            amount: 1000,
          ),
          balanceAfterMovement: 2000,
        ),
      ],
    );

    expect(report.title, 'TL Kasa - Hesap Ekstresi');
    expect(report.subtitle, contains('01.08.2026 - 31.08.2026'));
    expect(report.rows, hasLength(2));
    expect(report.metrics.map((item) => item.label), [
      'Dönem sonu bakiye',
      'Toplam giriş',
      'Toplam çıkış',
    ]);
  });
}

Transaction _transaction({
  required String id,
  required TransactionType type,
  required double amount,
}) => Transaction(
  id: id,
  accountId: 'account-1',
  creditCardId: null,
  amount: amount,
  transactionType: type,
  categoryId: null,
  merchant: id,
  note: null,
  transactionDate: DateTime(2026, 8, 15),
  source: TransactionSource.manual,
  isDeleted: false,
);
