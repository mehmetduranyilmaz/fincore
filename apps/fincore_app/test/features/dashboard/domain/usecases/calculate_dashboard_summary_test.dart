import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/accounts/domain/usecases/calculate_account_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/calculate_credit_card_balance.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/dashboard/domain/usecases/calculate_dashboard_summary.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('combines balances and current-month transaction analytics', () async {
    const accountRepository = _AccountRepository();
    const creditCardRepository = _CreditCardRepository();
    final transactionRepository = _TransactionRepository(_transactions());
    final useCase = CalculateDashboardSummaryUseCase(
      accountRepository,
      creditCardRepository,
      transactionRepository,
      CalculateAccountBalanceUseCase(transactionRepository),
      CalculateCreditCardBalanceUseCase(
        creditCardRepository,
        transactionRepository,
      ),
      clock: () => DateTime(2026, 7, 25),
    );

    final result = await useCase.execute();

    expect(
      result,
      const DashboardSummary(
        totalAccountBalances: 1700,
        totalCreditCardDebt: 350,
        totalAssets: 1700,
        netWorth: 1350,
        monthlyIncome: 1500,
        monthlyExpense: 500,
        monthlyCashFlow: 1000,
        transactionCount: 8,
      ),
    );
  });
}

List<Transaction> _transactions() {
  return [
    _transaction(
      id: 'account-1-income',
      accountId: 'account-1',
      amount: 1000,
      type: TransactionType.income,
    ),
    _transaction(
      id: 'account-1-expense',
      accountId: 'account-1',
      amount: 200,
      type: TransactionType.expense,
    ),
    _transaction(
      id: 'transfer-out',
      accountId: 'account-1',
      amount: -100,
      type: TransactionType.transfer,
    ),
    _transaction(
      id: 'transfer-in',
      accountId: 'account-2',
      amount: 100,
      type: TransactionType.transfer,
    ),
    _transaction(
      id: 'account-2-income',
      accountId: 'account-2',
      amount: 500,
      type: TransactionType.income,
    ),
    _transaction(
      id: 'card-expense',
      creditCardId: 'credit-card-1',
      amount: 300,
      type: TransactionType.expense,
    ),
    _transaction(
      id: 'card-payment',
      creditCardId: 'credit-card-1',
      amount: 50,
      type: TransactionType.income,
    ),
    _transaction(
      id: 'customer-card-payment',
      creditCardId: 'credit-card-1',
      amount: 100,
      type: TransactionType.expense,
      customerId: 'customer-1',
      customerBalanceDelta: 100,
      paymentGroupId: 'customer-payment-group',
    ),
    _transaction(
      id: 'old-income',
      accountId: 'account-1',
      amount: 400,
      type: TransactionType.income,
      date: DateTime(2026, 6, 30),
    ),
    _transaction(
      id: 'deleted-expense',
      accountId: 'account-1',
      amount: 900,
      type: TransactionType.expense,
      isDeleted: true,
    ),
  ];
}

Transaction _transaction({
  required String id,
  String? accountId,
  String? creditCardId,
  required double amount,
  required TransactionType type,
  DateTime? date,
  bool isDeleted = false,
  String? customerId,
  double? customerBalanceDelta,
  String? paymentGroupId,
}) {
  return Transaction(
    id: id,
    accountId: accountId,
    creditCardId: creditCardId,
    amount: amount,
    transactionType: type,
    categoryId: null,
    merchant: id,
    note: null,
    transactionDate: date ?? DateTime(2026, 7, 15),
    source: TransactionSource.manual,
    isDeleted: isDeleted,
    transferGroupId: type == TransactionType.transfer ? 'group-1' : null,
    customerId: customerId,
    customerBalanceDelta: customerBalanceDelta,
    paymentGroupId: paymentGroupId,
  );
}

final class _AccountRepository implements AccountRepository {
  const _AccountRepository();

  @override
  Future<List<Account>> getAccounts() async {
    return const [
      Account(
        id: 'account-1',
        name: 'Primary',
        type: AccountType.checking,
        currencyCode: 'TRY',
        isArchived: false,
      ),
      Account(
        id: 'account-2',
        name: 'Savings',
        type: AccountType.savings,
        currencyCode: 'TRY',
        isArchived: false,
      ),
    ];
  }
}

final class _CreditCardRepository implements CreditCardRepository {
  const _CreditCardRepository();

  @override
  Future<List<CreditCard>> getCreditCards() async {
    return const [
      CreditCard(
        id: 'credit-card-1',
        bankName: 'Bank',
        cardName: 'Card',
        lastFourDigits: '1111',
        creditLimit: 10000,
        statementDay: 10,
        dueDay: 20,
        currencyCode: 'TRY',
        isArchived: false,
      ),
    ];
  }
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.transactions);

  final List<Transaction> transactions;

  @override
  Future<void> create(Transaction transaction) async {}

  @override
  Future<void> createMany(List<Transaction> transactions) async {}

  @override
  Future<Transaction?> getById(String transactionId) async => null;

  @override
  Future<List<Transaction>> getTransactions(TransactionFilter filter) async {
    return transactions
        .where((transaction) {
          return (filter.accountId == null ||
                  transaction.accountId == filter.accountId) &&
              (filter.creditCardId == null ||
                  transaction.creditCardId == filter.creditCardId);
        })
        .toList(growable: false);
  }

  @override
  Future<void> update(Transaction transaction) async {}
}
