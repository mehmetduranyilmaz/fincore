import 'package:fincore_app/features/accounts/presentation/controllers/accounts_controller.dart';
import 'package:fincore_app/features/accounts/presentation/providers/account_balance_provider.dart';
import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/budgets/presentation/controllers/budgets_controller.dart';
import 'package:fincore_app/features/budgets/presentation/providers/budget_categories_provider.dart';
import 'package:fincore_app/features/categories/presentation/controllers/categories_controller.dart';
import 'package:fincore_app/features/categories/presentation/providers/category_provider.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_activity_summary_provider.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_balance_provider.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_payment_calendar_provider.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_statements_provider.dart';
import 'package:fincore_app/features/customers/presentation/controllers/customers_controller.dart';
import 'package:fincore_app/features/customers/presentation/providers/customer_balance_provider.dart';
import 'package:fincore_app/features/dashboard/presentation/providers/dashboard_summary_provider.dart';
import 'package:fincore_app/features/reports/presentation/providers/expense_category_report_provider.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/presentation/controllers/transactions_controller.dart';
import 'package:fincore_app/features/transactions/presentation/providers/transaction_details_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDataRefreshCoordinatorProvider = Provider<AppDataRefreshCoordinator>(
  AppDataRefreshCoordinator.new,
);

/// Keeps cached read models consistent after a successful command.
///
/// Future providers are invalidated eagerly but recomputed lazily by Riverpod:
/// an on-screen consumer refreshes immediately, while an inactive screen does
/// no work until it is opened. Stateful list controllers are loaded only when
/// their shell destination is selected.
final class AppDataRefreshCoordinator {
  const AppDataRefreshCoordinator(this._ref);

  final Ref _ref;

  Future<void> transactionsChanged({
    required Iterable<Transaction> current,
    Iterable<Transaction> previous = const <Transaction>[],
  }) async {
    final affected = [...previous, ...current];
    final transactionIds = _values(affected.map((item) => item.id));
    final accountIds = _values(affected.map((item) => item.accountId));
    final creditCardIds = _values(affected.map((item) => item.creditCardId));
    final customerIds = _values(affected.map((item) => item.customerId));

    for (final transactionId in transactionIds) {
      _ref.invalidate(transactionDetailsProvider(transactionId));
    }
    for (final accountId in accountIds) {
      _ref.invalidate(accountBalanceProvider(accountId));
      _ref.invalidate(accountHasMovementsProvider(accountId));
    }
    for (final creditCardId in creditCardIds) {
      _invalidateCreditCardTransactionReads(creditCardId);
    }
    for (final customerId in customerIds) {
      _ref.invalidate(customerBalanceProvider(customerId));
      _ref.invalidate(customerHasMovementsProvider(customerId));
      _ref.invalidate(customerMovementsProvider(customerId));
    }

    _ref.invalidate(dashboardSummaryProvider);
    _ref.invalidate(expenseCategoryReportProvider);
    _ref.invalidate(creditCardPaymentCalendarProvider);

    switch (_activeDestination) {
      case AppShellDestination.transactions:
        await _ref.read(transactionsControllerProvider.notifier).load();
      case AppShellDestination.budgets:
        await _ref.read(budgetsControllerProvider.notifier).load();
      case AppShellDestination.dashboard:
      case AppShellDestination.categories:
      case AppShellDestination.customers:
      case AppShellDestination.accounts:
      case AppShellDestination.creditCards:
      case AppShellDestination.reports:
      case AppShellDestination.settings:
        break;
    }
  }

  Future<void> accountChanged(String accountId) async {
    _ref.invalidate(accountProvider(accountId));
    _ref.invalidate(accountBalanceProvider(accountId));
    _ref.invalidate(accountHasMovementsProvider(accountId));
    _ref.invalidate(dashboardSummaryProvider);
    if (_activeDestination == AppShellDestination.accounts) {
      await _ref.read(accountsControllerProvider.notifier).load();
    }
  }

  Future<void> creditCardChanged(String creditCardId) async {
    _ref.invalidate(creditCardProvider(creditCardId));
    _invalidateCreditCardTransactionReads(creditCardId);
    _ref.invalidate(creditCardPaymentCalendarProvider);
    _ref.invalidate(dashboardSummaryProvider);
    if (_activeDestination == AppShellDestination.creditCards) {
      await _ref.read(creditCardsControllerProvider.notifier).load();
    }
  }

  Future<void> customerChanged(String customerId) async {
    _ref.invalidate(customerProvider(customerId));
    _ref.invalidate(customerBalanceProvider(customerId));
    _ref.invalidate(customerHasMovementsProvider(customerId));
    _ref.invalidate(customerMovementsProvider(customerId));
    if (_activeDestination == AppShellDestination.customers) {
      await _ref.read(customersControllerProvider.notifier).load();
    }
  }

  Future<void> categoryCreated(String categoryId) async {
    _ref.invalidate(categoryProvider(categoryId));
    _ref.invalidate(expenseBudgetCategoriesProvider);
    if (_activeDestination == AppShellDestination.categories) {
      await _ref.read(categoriesControllerProvider.notifier).load();
    }
  }

  Future<void> categoryChanged(String categoryId) async {
    await categoryCreated(categoryId);
    _ref.invalidate(expenseCategoryReportProvider);
    if (_activeDestination == AppShellDestination.budgets) {
      await _ref.read(budgetsControllerProvider.notifier).load();
    }
  }

  Future<void> budgetChanged() async {
    if (_activeDestination == AppShellDestination.budgets) {
      await _ref.read(budgetsControllerProvider.notifier).load();
    }
  }

  void recurringExpensePlanChanged() {
    _ref.invalidate(creditCardPaymentCalendarProvider);
  }

  Future<void> allDataRestored() async {
    _ref.invalidate(accountsControllerProvider);
    _ref.invalidate(budgetsControllerProvider);
    _ref.invalidate(categoriesControllerProvider);
    _ref.invalidate(creditCardsControllerProvider);
    _ref.invalidate(customersControllerProvider);
    _ref.invalidate(transactionsControllerProvider);

    _ref.invalidate(accountProvider);
    _ref.invalidate(accountBalanceProvider);
    _ref.invalidate(accountHasMovementsProvider);
    _ref.invalidate(categoryProvider);
    _ref.invalidate(creditCardProvider);
    _ref.invalidate(creditCardBalanceProvider);
    _ref.invalidate(creditCardActivitySummaryProvider);
    _ref.invalidate(creditCardCurrentPeriodTransactionsProvider);
    _ref.invalidate(creditCardFutureInstallmentsProvider);
    _ref.invalidate(creditCardStatementsProvider);
    _ref.invalidate(customerProvider);
    _ref.invalidate(customerBalanceProvider);
    _ref.invalidate(customerHasMovementsProvider);
    _ref.invalidate(customerMovementsProvider);
    _ref.invalidate(transactionDetailsProvider);

    _ref.invalidate(dashboardSummaryProvider);
    _ref.invalidate(expenseBudgetCategoriesProvider);
    _ref.invalidate(expenseCategoryReportProvider);
    _ref.invalidate(creditCardPaymentCalendarProvider);
  }

  void creditCardStatementChanged(String creditCardId) {
    _ref.invalidate(creditCardStatementsProvider(creditCardId));
    _ref.invalidate(creditCardActivitySummaryProvider(creditCardId));
    _ref.invalidate(creditCardCurrentPeriodTransactionsProvider(creditCardId));
    _ref.invalidate(creditCardFutureInstallmentsProvider(creditCardId));
  }

  AppShellDestination get _activeDestination =>
      _ref.read(appShellNavigationControllerProvider);

  void _invalidateCreditCardTransactionReads(String creditCardId) {
    _ref.invalidate(creditCardBalanceProvider(creditCardId));
    _ref.invalidate(creditCardActivitySummaryProvider(creditCardId));
    _ref.invalidate(creditCardCurrentPeriodTransactionsProvider(creditCardId));
    _ref.invalidate(creditCardFutureInstallmentsProvider(creditCardId));
    _ref.invalidate(creditCardStatementPaymentStatusProvider);
  }

  static Set<String> _values(Iterable<String?> values) {
    return values.nonNulls.toSet();
  }
}
