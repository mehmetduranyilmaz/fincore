import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/reports/domain/usecases/calculate_cash_flow_report.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'counts real account cash movements without card purchase duplication',
    () async {
      final report = await CalculateCashFlowReportUseCase(
        _Transactions([
          _item(
            'income',
            accountId: 'bank',
            amount: 130000,
            type: TransactionType.income,
          ),
          _item(
            'expense',
            accountId: 'cash',
            amount: 95000,
            type: TransactionType.expense,
          ),
          _item(
            'card-purchase',
            cardId: 'card',
            amount: 10000,
            type: TransactionType.expense,
          ),
          _item(
            'card-payment-account',
            accountId: 'bank',
            amount: -10000,
            type: TransactionType.transfer,
            paymentGroupId: 'card-payment',
          ),
          _item(
            'card-payment-card',
            cardId: 'card',
            amount: 10000,
            type: TransactionType.income,
            paymentGroupId: 'card-payment',
          ),
        ]),
        const _Accounts(),
      ).execute(startDate: DateTime(2026, 8), endDate: DateTime(2026, 8, 31));

      expect(report.totalInflows, {'TRY': 130000});
      expect(report.totalOutflows, {'TRY': 105000});
      expect(report.netByCurrency, {'TRY': 25000});
      expect(
        report.outflows.map((item) => item.transactionId),
        contains('card-payment-account'),
      );
      expect(
        report.outflows.map((item) => item.transactionId),
        isNot(contains('card-purchase')),
      );
    },
  );
}

Transaction _item(
  String id, {
  String? accountId,
  String? cardId,
  required double amount,
  required TransactionType type,
  String? paymentGroupId,
}) => Transaction(
  id: id,
  accountId: accountId,
  creditCardId: cardId,
  amount: amount,
  transactionType: type,
  categoryId: null,
  merchant: id,
  note: null,
  transactionDate: DateTime(2026, 8, 15),
  source: TransactionSource.manual,
  isDeleted: false,
  paymentGroupId: paymentGroupId,
);

final class _Accounts implements AccountRepository {
  const _Accounts();
  @override
  Future<List<Account>> getAccounts() async => const [
    Account(
      id: 'bank',
      name: 'Banka',
      type: AccountType.checking,
      currencyCode: 'TRY',
      isArchived: false,
    ),
    Account(
      id: 'cash',
      name: 'Kasa',
      type: AccountType.cash,
      currencyCode: 'TRY',
      isArchived: false,
    ),
  ];
}

final class _Transactions implements TransactionRepository {
  const _Transactions(this.items);
  final List<Transaction> items;
  @override
  Future<void> create(Transaction transaction) async {}
  @override
  Future<void> createMany(List<Transaction> transactions) async {}
  @override
  Future<Transaction?> getById(String transactionId) async => null;
  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async =>
      items;
  @override
  Future<void> update(Transaction transaction) async {}
}
