import 'package:fincore_app/features/customers/domain/entities/customer_payment_input.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String profile = '/profile';
  static const String dashboard = '/dashboard';
  static const String createManualExpense = '/transactions/manual-expense';
  static const String createManualIncome = '/transactions/manual-income';
  static const String createTransfer = '/transactions/transfer';
  static const String createReceiptExpense = '/transactions/receipt-expense';
  static const String recurringExpenses = '/transactions/recurring-expenses';
  static const String editRecurringExpense =
      '/transactions/recurring-expenses/:planId/edit';
  static const String transactionDetails = '/transactions/:transactionId';
  static const String editTransaction = '/transactions/:transactionId/edit';
  static const String convertTransactionInstallments =
      '/transactions/:transactionId/installments';
  static const String createCategory = '/categories/create';
  static const String editCategory = '/categories/:categoryId/edit';
  static const String createBudget = '/budgets/create';
  static const String editBudget = '/budgets/:budgetId/edit';
  static const String createCreditCard = '/credit-cards/create';
  static const String editCreditCard = '/credit-cards/:creditCardId/edit';
  static const String creditCardPayment = '/credit-cards/:creditCardId/payment';
  static const String creditCardStatements =
      '/credit-cards/:creditCardId/statements';
  static const String createCreditCardStatement =
      '/credit-cards/:creditCardId/statements/create';
  static const String creditCardCurrentPeriod =
      '/credit-cards/:creditCardId/current-period';
  static const String creditCardFutureInstallments =
      '/credit-cards/:creditCardId/future-installments';
  static const String creditCardPaymentCalendar =
      '/credit-cards/payment-calendar';
  static const String createCustomer = '/customers/create';
  static const String editCustomer = '/customers/:customerId/edit';
  static const String customerPayment =
      '/customers/:customerId/payment/:direction';
  static const String customerMovements = '/customers/:customerId/movements';
  static const String createAccount = '/accounts/create';
  static const String editAccount = '/accounts/:accountId/edit';
  static const String accountMovements = '/accounts/:accountId/movements';
  static const String cashFlow = '/reports/cash-flow';

  static String transactionDetailsLocation(String transactionId) {
    return '/transactions/${Uri.encodeComponent(transactionId)}';
  }

  static String editRecurringExpenseLocation(String planId) {
    return '/transactions/recurring-expenses/${Uri.encodeComponent(planId)}/edit';
  }

  static String editTransactionLocation(String transactionId) {
    return '${transactionDetailsLocation(transactionId)}/edit';
  }

  static String convertTransactionInstallmentsLocation(String transactionId) {
    return '${transactionDetailsLocation(transactionId)}/installments';
  }

  static String editCategoryLocation(String categoryId) {
    return '/categories/${Uri.encodeComponent(categoryId)}/edit';
  }

  static String editBudgetLocation(String budgetId) {
    return '/budgets/${Uri.encodeComponent(budgetId)}/edit';
  }

  static String editCreditCardLocation(String creditCardId) {
    return '/credit-cards/${Uri.encodeComponent(creditCardId)}/edit';
  }

  static String creditCardPaymentLocation(
    String creditCardId, {
    String? statementId,
  }) {
    final path = '/credit-cards/${Uri.encodeComponent(creditCardId)}/payment';
    return statementId == null
        ? path
        : Uri(
            path: path,
            queryParameters: {'statementId': statementId},
          ).toString();
  }

  static String creditCardStatementsLocation(String creditCardId) {
    return '/credit-cards/${Uri.encodeComponent(creditCardId)}/statements';
  }

  static String createCreditCardStatementLocation(String creditCardId) {
    return '${creditCardStatementsLocation(creditCardId)}/create';
  }

  static String creditCardCurrentPeriodLocation(String creditCardId) {
    return '/credit-cards/${Uri.encodeComponent(creditCardId)}/current-period';
  }

  static String creditCardFutureInstallmentsLocation(String creditCardId) {
    return '/credit-cards/${Uri.encodeComponent(creditCardId)}/future-installments';
  }

  static String customerPaymentLocation(
    String customerId,
    CustomerPaymentDirection direction,
  ) {
    return '/customers/${Uri.encodeComponent(customerId)}/payment/${direction.name}';
  }

  static String editCustomerLocation(String customerId) {
    return '/customers/${Uri.encodeComponent(customerId)}/edit';
  }

  static String customerMovementsLocation(String customerId) {
    return '/customers/${Uri.encodeComponent(customerId)}/movements';
  }

  static String editAccountLocation(String accountId) {
    return '/accounts/${Uri.encodeComponent(accountId)}/edit';
  }

  static String accountMovementsLocation(String accountId) {
    return '/accounts/${Uri.encodeComponent(accountId)}/movements';
  }
}
