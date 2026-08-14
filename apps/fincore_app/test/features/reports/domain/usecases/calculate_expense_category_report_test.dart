import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/entities/account_type.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/reports/domain/entities/expense_report_period.dart';
import 'package:fincore_app/features/reports/domain/usecases/calculate_expense_category_report.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_source.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups expenses by category and keeps currencies separate', () async {
    final useCase = CalculateExpenseCategoryReportUseCase(
      _TransactionRepository(_transactions),
      const _CategoryRepository(),
      const _AccountRepository(),
      const _CreditCardRepository(),
      const _CustomerRepository(),
    );

    final result = await useCase.execute(
      ExpenseReportPeriod.month(DateTime(2026, 8, 10)),
    );

    expect(result.currencies.map((item) => item.currencyCode), ['TRY', 'USD']);
    final tryReport = result.currencies.first;
    expect(tryReport.totalAmount, 375);
    expect(tryReport.transactionCount, 3);
    expect(tryReport.averageTransactionAmount, 125);
    expect(tryReport.categories.map((item) => item.name), [
      'Groceries',
      'Kategorisiz',
    ]);
    expect(tryReport.categories.first.amount, 275);
    expect(tryReport.categories.first.percentage, closeTo(275 / 375, 0.0001));
    expect(tryReport.categories.last.amount, 100);
    expect(result.currencies.last.totalAmount, 50);
  });

  test('monthly and yearly periods navigate with normalized boundaries', () {
    final month = ExpenseReportPeriod.month(DateTime(2026, 1, 20));
    expect(month.previous().anchor, DateTime(2025, 12));
    expect(month.endDate, DateTime(2026, 1, 31));

    final year = month.changeType(ExpenseReportPeriodType.yearly);
    expect(year.startDate, DateTime(2026));
    expect(year.endDate, DateTime(2026, 12, 31));
    expect(year.next().anchor, DateTime(2027));
  });
}

final _transactions = [
  _transaction(
    id: 'market',
    accountId: 'try-account',
    amount: 200,
    categoryId: 'category-grocery',
  ),
  _transaction(id: 'uncategorized', accountId: 'try-account', amount: 100),
  _transaction(
    id: 'usd-market',
    creditCardId: 'usd-card',
    amount: 50,
    categoryId: 'category-grocery',
  ),
  _transaction(
    id: 'open-account-training',
    amount: 75,
    categoryId: 'category-grocery',
    customerId: 'customer-1',
    customerBalanceDelta: -75,
  ),
  _transaction(
    id: 'old-expense',
    accountId: 'try-account',
    amount: 900,
    categoryId: 'category-grocery',
    date: DateTime(2026, 7, 31),
  ),
  _transaction(
    id: 'deleted-expense',
    accountId: 'try-account',
    amount: 800,
    categoryId: 'category-grocery',
    isDeleted: true,
  ),
  _transaction(
    id: 'income',
    accountId: 'try-account',
    amount: 700,
    type: TransactionType.income,
  ),
  _transaction(
    id: 'customer-card-payment',
    creditCardId: 'usd-card',
    amount: 400,
    customerId: 'customer-1',
    customerBalanceDelta: 400,
    paymentGroupId: 'customer-payment-group',
  ),
];

Transaction _transaction({
  required String id,
  String? accountId,
  String? creditCardId,
  required double amount,
  String? categoryId,
  DateTime? date,
  bool isDeleted = false,
  TransactionType type = TransactionType.expense,
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
    categoryId: categoryId,
    merchant: id,
    note: null,
    transactionDate: date ?? DateTime(2026, 8, 5),
    source: TransactionSource.manual,
    isDeleted: isDeleted,
    customerId: customerId,
    customerBalanceDelta: customerBalanceDelta,
    paymentGroupId: paymentGroupId,
  );
}

final class _TransactionRepository implements TransactionRepository {
  const _TransactionRepository(this.items);

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

final class _CategoryRepository implements CategoryRepository {
  const _CategoryRepository();

  static const category = Category(
    id: 'category-grocery',
    name: 'Groceries',
    icon: 'shopping_cart',
    color: 0xFF2E7D32,
    type: CategoryType.expense,
  );

  @override
  Future<void> create(Category category) async {}

  @override
  Future<void> delete(String categoryId) async {}

  @override
  Future<List<Category>> getAll() async => const [category];

  @override
  Future<Category?> getById(String categoryId) async =>
      categoryId == category.id ? category : null;

  @override
  Future<void> update(Category category) async {}
}

final class _AccountRepository implements AccountRepository {
  const _AccountRepository();

  @override
  Future<List<Account>> getAccounts() async => const [
    Account(
      id: 'try-account',
      name: 'TL Hesabı',
      type: AccountType.checking,
      currencyCode: 'TRY',
      isArchived: false,
    ),
  ];
}

final class _CreditCardRepository implements CreditCardRepository {
  const _CreditCardRepository();

  @override
  Future<List<CreditCard>> getCreditCards() async => const [
    CreditCard(
      id: 'usd-card',
      bankName: 'Banka',
      cardName: 'USD Kart',
      lastFourDigits: '1234',
      creditLimit: 1000,
      statementDay: 10,
      dueDay: 20,
      currencyCode: 'USD',
      isArchived: false,
    ),
  ];
}

final class _CustomerRepository implements CustomerRepository {
  const _CustomerRepository();

  static const customer = Customer(
    id: 'customer-1',
    name: 'Eğitim Kurumu',
    openingBalance: 0,
    currencyCode: 'TRY',
    isArchived: false,
  );

  @override
  Future<void> archive(String customerId) async {}

  @override
  Future<void> create(Customer customer) async {}

  @override
  Future<Customer?> getById(String customerId) async =>
      customerId == customer.id ? customer : null;

  @override
  Future<List<Customer>> getCustomers() async => const [customer];

  @override
  Future<void> update(Customer customer) async {}
}
