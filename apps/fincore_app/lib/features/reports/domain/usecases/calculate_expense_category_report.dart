import 'package:fincore_app/features/accounts/domain/entities/account.dart';
import 'package:fincore_app/features/accounts/domain/repositories/account_repository.dart';
import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/customers/domain/repositories/customer_repository.dart';
import 'package:fincore_app/features/customers/domain/entities/customer.dart';
import 'package:fincore_app/features/reports/domain/entities/expense_category_report.dart';
import 'package:fincore_app/features/reports/domain/entities/expense_report_period.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction_type.dart';
import 'package:fincore_app/features/transactions/domain/repositories/transaction_repository.dart';

final class CalculateExpenseCategoryReportUseCase {
  const CalculateExpenseCategoryReportUseCase(
    this._transactionRepository,
    this._categoryRepository,
    this._accountRepository,
    this._creditCardRepository,
    this._customerRepository,
  );

  static const String unknownCurrencyCode = 'N/A';
  static const String uncategorizedName = 'Kategorisiz';
  static const String deletedCategoryName = 'Silinmiş Kategori';

  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final AccountRepository _accountRepository;
  final CreditCardRepository _creditCardRepository;
  final CustomerRepository _customerRepository;

  Future<ExpenseCategoryReport> execute(ExpenseReportPeriod period) async {
    final results = await Future.wait<Object>([
      _transactionRepository.getTransactions(
        TransactionFilter(
          transactionTypes: const {TransactionType.expense},
          startDate: period.startDate,
          endDate: period.endDate,
        ),
      ),
      _categoryRepository.getAll(),
      _accountRepository.getAccounts(),
      _creditCardRepository.getCreditCards(),
      _customerRepository.getCustomers(),
    ]);
    final transactions = results[0] as List<Transaction>;
    final categories = results[1] as List<Category>;
    final accounts = results[2] as List<Account>;
    final creditCards = results[3] as List<CreditCard>;
    final customers = results[4] as List<Customer>;
    final accountCurrencies = {
      for (final account in accounts) account.id: account.currencyCode,
    };
    final cardCurrencies = {
      for (final card in creditCards) card.id: card.currencyCode,
    };
    final customerCurrencies = {
      for (final customer in customers) customer.id: customer.currencyCode,
    };
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final grouped = <String, Map<String, _CategoryAccumulator>>{};

    for (final transaction in transactions) {
      if (!_belongsToPeriod(transaction, period)) continue;
      final currencyCode = transaction.accountId != null
          ? accountCurrencies[transaction.accountId]
          : transaction.creditCardId != null
          ? cardCurrencies[transaction.creditCardId]
          : customerCurrencies[transaction.customerId];
      final normalizedCurrency = currencyCode ?? unknownCurrencyCode;
      final categoryKey = transaction.categoryId ?? _uncategorizedKey;
      final category = transaction.categoryId == null
          ? null
          : categoryById[transaction.categoryId];
      final accumulator = grouped
          .putIfAbsent(normalizedCurrency, () => {})
          .putIfAbsent(
            categoryKey,
            () => _CategoryAccumulator.fromCategory(
              category,
              hasDeletedCategory: transaction.categoryId != null,
            ),
          );
      accumulator.add(transaction);
    }

    final currencyReports = <CurrencyExpenseReport>[];
    for (final currencyEntry in grouped.entries) {
      final total = currencyEntry.value.values.fold(
        0.0,
        (sum, category) => sum + category.amount,
      );
      final categories =
          currencyEntry.value.values
              .map((item) => item.toBreakdown(total))
              .toList()
            ..sort((left, right) {
              final byAmount = right.amount.compareTo(left.amount);
              return byAmount != 0
                  ? byAmount
                  : left.name.toLowerCase().compareTo(right.name.toLowerCase());
            });
      currencyReports.add(
        CurrencyExpenseReport(
          currencyCode: currencyEntry.key,
          totalAmount: total,
          transactionCount: categories.fold(
            0,
            (sum, category) => sum + category.transactionCount,
          ),
          categories: categories,
        ),
      );
    }
    currencyReports.sort((left, right) {
      if (left.currencyCode == 'TRY') return -1;
      if (right.currencyCode == 'TRY') return 1;
      return left.currencyCode.compareTo(right.currencyCode);
    });
    return ExpenseCategoryReport(period: period, currencies: currencyReports);
  }

  static bool _belongsToPeriod(
    Transaction transaction,
    ExpenseReportPeriod period,
  ) {
    return !transaction.isDeleted &&
        transaction.isActualExpense &&
        !transaction.transactionDate.isBefore(period.startDate) &&
        !transaction.transactionDate.isAfter(period.endDate);
  }

  static const String _uncategorizedKey = '__uncategorized__';
}

final class _CategoryAccumulator {
  _CategoryAccumulator({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory _CategoryAccumulator.fromCategory(
    Category? category, {
    required bool hasDeletedCategory,
  }) {
    return _CategoryAccumulator(
      categoryId: category?.id,
      name:
          category?.name ??
          (hasDeletedCategory
              ? CalculateExpenseCategoryReportUseCase.deletedCategoryName
              : CalculateExpenseCategoryReportUseCase.uncategorizedName),
      icon: category?.icon ?? 'category',
      color: category?.color ?? 0xFF757575,
    );
  }

  final String? categoryId;
  final String name;
  final String icon;
  final int color;
  double amount = 0;
  final List<ExpenseReportTransaction> transactions = [];

  void add(Transaction transaction) {
    final expenseAmount = transaction.amount.abs();
    amount += expenseAmount;
    transactions.add(
      ExpenseReportTransaction(
        id: transaction.id,
        description: transaction.merchant,
        date: transaction.transactionDate,
        amount: expenseAmount,
      ),
    );
  }

  CategoryExpenseBreakdown toBreakdown(double totalAmount) {
    transactions.sort((left, right) {
      final byDate = right.date.compareTo(left.date);
      return byDate != 0 ? byDate : right.id.compareTo(left.id);
    });
    return CategoryExpenseBreakdown(
      categoryId: categoryId,
      name: name,
      icon: icon,
      color: color,
      amount: amount,
      percentage: totalAmount == 0 ? 0 : amount / totalAmount,
      transactionCount: transactions.length,
      transactions: transactions,
    );
  }
}
