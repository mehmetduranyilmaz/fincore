import 'package:fincore_app/core/di/datasources.dart';
import 'package:fincore_app/core/di/repositories.dart';
import 'package:fincore_app/features/accounts/domain/usecases/get_accounts.dart';
import 'package:fincore_app/features/accounts/domain/usecases/calculate_account_balance.dart';
import 'package:fincore_app/features/accounts/domain/usecases/create_account.dart';
import 'package:fincore_app/features/accounts/domain/usecases/delete_account.dart';
import 'package:fincore_app/features/accounts/domain/usecases/update_account.dart';
import 'package:fincore_app/features/auth/application/auth_session_manager.dart';
import 'package:fincore_app/features/auth/domain/usecases/initialize_app.dart';
import 'package:fincore_app/features/auth/domain/usecases/login_user.dart';
import 'package:fincore_app/features/auth/domain/usecases/refresh_session.dart';
import 'package:fincore_app/features/auth/domain/usecases/get_user_credentials_profile.dart';
import 'package:fincore_app/features/auth/domain/usecases/update_user_credentials.dart';
import 'package:fincore_app/features/budgets/domain/usecases/calculate_budget_progress.dart';
import 'package:fincore_app/features/budgets/domain/usecases/create_budget.dart';
import 'package:fincore_app/features/budgets/domain/usecases/delete_budget.dart';
import 'package:fincore_app/features/budgets/domain/usecases/get_budgets.dart';
import 'package:fincore_app/features/budgets/domain/usecases/update_budget.dart';
import 'package:fincore_app/features/categories/domain/usecases/create_category.dart';
import 'package:fincore_app/features/categories/domain/usecases/delete_category.dart';
import 'package:fincore_app/features/categories/domain/usecases/get_categories.dart';
import 'package:fincore_app/features/categories/domain/usecases/get_category.dart';
import 'package:fincore_app/features/categories/domain/usecases/update_category.dart';
import 'package:fincore_app/features/categories/data/services/category_assignment_validator.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_cards.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/calculate_credit_card_balance.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/create_credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/delete_credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_activity_summary.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_current_period_transactions.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_future_installments.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_payment_calendar.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/create_credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_statement_candidates.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_statement_payment_status.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_card_statements.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/update_credit_card.dart';
import 'package:fincore_app/features/dashboard/domain/usecases/calculate_dashboard_summary.dart';
import 'package:fincore_app/features/reports/domain/usecases/calculate_expense_category_report.dart';
import 'package:fincore_app/features/customers/domain/usecases/calculate_customer_balance.dart';
import 'package:fincore_app/features/customers/domain/usecases/create_credit_card_payment.dart';
import 'package:fincore_app/features/customers/domain/usecases/create_customer.dart';
import 'package:fincore_app/features/customers/domain/usecases/create_customer_payment.dart';
import 'package:fincore_app/features/customers/domain/usecases/delete_customer.dart';
import 'package:fincore_app/features/customers/domain/usecases/get_customers.dart';
import 'package:fincore_app/features/customers/domain/usecases/get_customer_movements.dart';
import 'package:fincore_app/features/customers/domain/usecases/update_customer.dart';
import 'package:fincore_app/features/customers/domain/usecases/update_customer_payment.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_manual_expense.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/usecases/delete_recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_receipt_expense.dart';
import 'package:fincore_app/features/transactions/domain/usecases/convert_expense_to_installments.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_manual_income.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_transfer.dart';
import 'package:fincore_app/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:fincore_app/features/transactions/domain/usecases/get_transactions.dart';
import 'package:fincore_app/features/transactions/domain/usecases/update_recurring_expense_plan.dart';
import 'package:fincore_app/features/transactions/domain/usecases/get_transaction_details.dart';
import 'package:fincore_app/features/transactions/domain/usecases/update_transaction.dart';
import 'package:fincore_app/features/transactions/domain/usecases/parse_receipt_text.dart';
import 'package:fincore_app/features/transactions/domain/usecases/scan_receipt.dart';
import 'package:fincore_app/features/transactions/domain/services/transaction_category_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final initializeAppProvider = Provider<InitializeApp>(
  (ref) => InitializeApp(ref.watch(authRepositoryProvider)),
);

final loginUserProvider = Provider<LoginUser>(
  (ref) => LoginUser(ref.watch(authRepositoryProvider)),
);

final Provider<AuthSessionManager> authSessionManagerProvider =
    Provider<AuthSessionManager>((ref) {
      final manager = AuthSessionManager(ref.watch(authRepositoryProvider));

      ref.onDispose(manager.dispose);

      return manager;
    });

final Provider<RefreshSession> refreshSessionProvider =
    Provider<RefreshSession>(
      (ref) => RefreshSession(ref.watch(authRepositoryProvider)),
    );

final getUserCredentialsProfileProvider = Provider<GetUserCredentialsProfile>(
  (ref) =>
      GetUserCredentialsProfile(ref.watch(userCredentialsRepositoryProvider)),
);

final updateUserCredentialsProvider = Provider<UpdateUserCredentials>(
  (ref) => UpdateUserCredentials(ref.watch(userCredentialsRepositoryProvider)),
);

final Provider<CalculateDashboardSummaryUseCase>
calculateDashboardSummaryProvider = Provider<CalculateDashboardSummaryUseCase>(
  (ref) => CalculateDashboardSummaryUseCase(
    ref.watch(accountRepositoryProvider),
    ref.watch(creditCardRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(calculateAccountBalanceProvider),
    ref.watch(calculateCreditCardBalanceProvider),
  ),
);

final Provider<CalculateExpenseCategoryReportUseCase>
calculateExpenseCategoryReportProvider =
    Provider<CalculateExpenseCategoryReportUseCase>(
      (ref) => CalculateExpenseCategoryReportUseCase(
        ref.watch(transactionRepositoryProvider),
        ref.watch(categoryRepositoryProvider),
        ref.watch(accountRepositoryProvider),
        ref.watch(creditCardRepositoryProvider),
        ref.watch(customerRepositoryProvider),
      ),
    );

final Provider<GetAccounts> getAccountsProvider = Provider<GetAccounts>(
  (ref) => GetAccounts(ref.watch(accountRepositoryProvider)),
);

final Provider<CreateAccountUseCase> createAccountProvider =
    Provider<CreateAccountUseCase>(
      (ref) => CreateAccountUseCase(
        ref.watch(accountCommandRepositoryProvider),
        ref.watch(accountRepositoryProvider),
      ),
    );

final Provider<UpdateAccountUseCase> updateAccountProvider =
    Provider<UpdateAccountUseCase>(
      (ref) => UpdateAccountUseCase(
        ref.watch(accountCommandRepositoryProvider),
        ref.watch(accountRepositoryProvider),
        ref.watch(transactionRepositoryProvider),
      ),
    );

final Provider<DeleteAccountUseCase> deleteAccountProvider =
    Provider<DeleteAccountUseCase>(
      (ref) => DeleteAccountUseCase(
        ref.watch(accountCommandRepositoryProvider),
        ref.watch(calculateAccountBalanceProvider),
        ref.watch(accountUsageRepositoryProvider),
      ),
    );

final Provider<CalculateAccountBalanceUseCase> calculateAccountBalanceProvider =
    Provider<CalculateAccountBalanceUseCase>(
      (ref) => CalculateAccountBalanceUseCase(
        ref.watch(transactionRepositoryProvider),
        accountRepository: ref.watch(accountRepositoryProvider),
      ),
    );

final Provider<GetCreditCards> getCreditCardsProvider =
    Provider<GetCreditCards>(
      (ref) => GetCreditCards(ref.watch(creditCardRepositoryProvider)),
    );

final Provider<CreateCreditCardUseCase> createCreditCardProvider =
    Provider<CreateCreditCardUseCase>(
      (ref) => CreateCreditCardUseCase(
        ref.watch(creditCardCommandRepositoryProvider),
        lookupRepository: ref.watch(creditCardRepositoryProvider),
      ),
    );

final Provider<UpdateCreditCardUseCase> updateCreditCardProvider =
    Provider<UpdateCreditCardUseCase>(
      (ref) => UpdateCreditCardUseCase(
        ref.watch(creditCardCommandRepositoryProvider),
        lookupRepository: ref.watch(creditCardRepositoryProvider),
      ),
    );

final Provider<DeleteCreditCardUseCase> deleteCreditCardProvider =
    Provider<DeleteCreditCardUseCase>(
      (ref) => DeleteCreditCardUseCase(
        ref.watch(creditCardCommandRepositoryProvider),
        ref.watch(creditCardUsageRepositoryProvider),
      ),
    );

final Provider<CalculateCreditCardBalanceUseCase>
calculateCreditCardBalanceProvider =
    Provider<CalculateCreditCardBalanceUseCase>(
      (ref) => CalculateCreditCardBalanceUseCase(
        ref.watch(creditCardRepositoryProvider),
        ref.watch(transactionRepositoryProvider),
      ),
    );

final Provider<GetCreditCardActivitySummaryUseCase>
getCreditCardActivitySummaryProvider =
    Provider<GetCreditCardActivitySummaryUseCase>(
      (ref) => GetCreditCardActivitySummaryUseCase(
        ref.watch(transactionRepositoryProvider),
        statementRepository: ref.watch(creditCardStatementRepositoryProvider),
      ),
    );

final Provider<GetCreditCardCurrentPeriodTransactionsUseCase>
getCreditCardCurrentPeriodTransactionsProvider =
    Provider<GetCreditCardCurrentPeriodTransactionsUseCase>(
      (ref) => GetCreditCardCurrentPeriodTransactionsUseCase(
        ref.watch(transactionRepositoryProvider),
        ref.watch(creditCardStatementRepositoryProvider),
      ),
    );

final Provider<GetCreditCardFutureInstallmentsUseCase>
getCreditCardFutureInstallmentsProvider =
    Provider<GetCreditCardFutureInstallmentsUseCase>(
      (ref) => GetCreditCardFutureInstallmentsUseCase(
        ref.watch(transactionRepositoryProvider),
        ref.watch(creditCardStatementRepositoryProvider),
      ),
    );

final Provider<GetCreditCardPaymentCalendarUseCase>
getCreditCardPaymentCalendarProvider =
    Provider<GetCreditCardPaymentCalendarUseCase>(
      (ref) => GetCreditCardPaymentCalendarUseCase(
        ref.watch(creditCardRepositoryProvider),
        ref.watch(transactionRepositoryProvider),
        recurringExpensePlanRepository: ref.watch(
          recurringExpensePlanRepositoryProvider,
        ),
      ),
    );

final Provider<GetCreditCardStatementsUseCase> getCreditCardStatementsProvider =
    Provider<GetCreditCardStatementsUseCase>(
      (ref) => GetCreditCardStatementsUseCase(
        ref.watch(creditCardStatementRepositoryProvider),
      ),
    );

final Provider<GetCreditCardStatementPaymentStatusUseCase>
getCreditCardStatementPaymentStatusProvider =
    Provider<GetCreditCardStatementPaymentStatusUseCase>(
      (ref) => GetCreditCardStatementPaymentStatusUseCase(
        ref.watch(creditCardStatementRepositoryProvider),
        ref.watch(transactionRepositoryProvider),
      ),
    );

final Provider<GetCreditCardStatementCandidatesUseCase>
getCreditCardStatementCandidatesProvider =
    Provider<GetCreditCardStatementCandidatesUseCase>(
      (ref) => GetCreditCardStatementCandidatesUseCase(
        ref.watch(creditCardStatementRepositoryProvider),
        ref.watch(transactionRepositoryProvider),
      ),
    );

final Provider<CreateCreditCardStatementUseCase>
createCreditCardStatementProvider = Provider<CreateCreditCardStatementUseCase>(
  (ref) => CreateCreditCardStatementUseCase(
    ref.watch(creditCardStatementRepositoryProvider),
    ref.watch(creditCardCommandRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

final Provider<GetTransactions> getTransactionsProvider =
    Provider<GetTransactions>(
      (ref) => GetTransactions(ref.watch(transactionRepositoryProvider)),
    );

final Provider<GetCustomersUseCase> getCustomersProvider =
    Provider<GetCustomersUseCase>(
      (ref) => GetCustomersUseCase(ref.watch(customerRepositoryProvider)),
    );

final Provider<CreateCustomerUseCase> createCustomerProvider =
    Provider<CreateCustomerUseCase>(
      (ref) => CreateCustomerUseCase(ref.watch(customerRepositoryProvider)),
    );

final Provider<UpdateCustomerUseCase> updateCustomerProvider =
    Provider<UpdateCustomerUseCase>(
      (ref) => UpdateCustomerUseCase(
        ref.watch(customerRepositoryProvider),
        ref.watch(transactionRepositoryProvider),
      ),
    );

final Provider<CalculateCustomerBalanceUseCase>
calculateCustomerBalanceProvider = Provider<CalculateCustomerBalanceUseCase>(
  (ref) => CalculateCustomerBalanceUseCase(
    ref.watch(customerRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

final Provider<DeleteCustomerUseCase> deleteCustomerProvider =
    Provider<DeleteCustomerUseCase>(
      (ref) => DeleteCustomerUseCase(
        ref.watch(customerRepositoryProvider),
        ref.watch(calculateCustomerBalanceProvider),
        ref.watch(customerUsageRepositoryProvider),
      ),
    );

final Provider<CreateCreditCardPaymentUseCase> createCreditCardPaymentProvider =
    Provider<CreateCreditCardPaymentUseCase>(
      (ref) => CreateCreditCardPaymentUseCase(
        ref.watch(transactionRepositoryProvider),
        ref.watch(accountRepositoryProvider),
        ref.watch(creditCardRepositoryProvider),
        ref.watch(creditCardStatementRepositoryProvider),
        ref.watch(calculateAccountBalanceProvider),
        ref.watch(calculateCreditCardBalanceProvider),
      ),
    );

final Provider<CreateCustomerPaymentUseCase> createCustomerPaymentProvider =
    Provider<CreateCustomerPaymentUseCase>(
      (ref) => CreateCustomerPaymentUseCase(
        ref.watch(transactionRepositoryProvider),
        ref.watch(customerRepositoryProvider),
        ref.watch(accountRepositoryProvider),
        ref.watch(creditCardRepositoryProvider),
        ref.watch(calculateAccountBalanceProvider),
        ref.watch(calculateCreditCardBalanceProvider),
      ),
    );

final Provider<UpdateCustomerPaymentUseCase> updateCustomerPaymentProvider =
    Provider<UpdateCustomerPaymentUseCase>(
      (ref) => UpdateCustomerPaymentUseCase(
        ref.watch(transactionRepositoryProvider),
        ref.watch(customerRepositoryProvider),
        ref.watch(accountRepositoryProvider),
        ref.watch(creditCardRepositoryProvider),
        ref.watch(calculateAccountBalanceProvider),
        ref.watch(calculateCreditCardBalanceProvider),
      ),
    );

final Provider<GetCustomerMovementsUseCase> getCustomerMovementsProvider =
    Provider<GetCustomerMovementsUseCase>(
      (ref) => GetCustomerMovementsUseCase(
        ref.watch(transactionRepositoryProvider),
        ref.watch(customerRepositoryProvider),
      ),
    );

final Provider<GetTransactionDetailsUseCase> getTransactionDetailsProvider =
    Provider<GetTransactionDetailsUseCase>(
      (ref) => GetTransactionDetailsUseCase(
        ref.watch(transactionRepositoryProvider),
      ),
    );

final Provider<UpdateTransactionUseCase> updateTransactionProvider =
    Provider<UpdateTransactionUseCase>(
      (ref) => UpdateTransactionUseCase(
        ref.watch(transactionRepositoryProvider),
        categoryValidator: ref.watch(transactionCategoryValidatorProvider),
        customerRepository: ref.watch(customerRepositoryProvider),
      ),
    );

final Provider<CreateManualExpenseUseCase> createManualExpenseProvider =
    Provider<CreateManualExpenseUseCase>(
      (ref) => CreateManualExpenseUseCase(
        ref.watch(transactionRepositoryProvider),
        installmentRepository: ref.watch(
          installmentTransactionRepositoryProvider,
        ),
        categoryValidator: ref.watch(transactionCategoryValidatorProvider),
        customerRepository: ref.watch(customerRepositoryProvider),
      ),
    );

final Provider<CreateRecurringExpensePlanUseCase>
createRecurringExpensePlanProvider =
    Provider<CreateRecurringExpensePlanUseCase>(
      (ref) => CreateRecurringExpensePlanUseCase(
        ref.watch(recurringExpensePlanRepositoryProvider),
        ref.watch(accountRepositoryProvider),
        ref.watch(creditCardRepositoryProvider),
        ref.watch(customerRepositoryProvider),
        categoryValidator: ref.watch(transactionCategoryValidatorProvider),
      ),
    );

final Provider<UpdateRecurringExpensePlanUseCase>
updateRecurringExpensePlanProvider =
    Provider<UpdateRecurringExpensePlanUseCase>(
      (ref) => UpdateRecurringExpensePlanUseCase(
        ref.watch(recurringExpensePlanRepositoryProvider),
        ref.watch(accountRepositoryProvider),
        ref.watch(creditCardRepositoryProvider),
        ref.watch(customerRepositoryProvider),
        categoryValidator: ref.watch(transactionCategoryValidatorProvider),
      ),
    );

final Provider<DeleteRecurringExpensePlanUseCase>
deleteRecurringExpensePlanProvider =
    Provider<DeleteRecurringExpensePlanUseCase>(
      (ref) => DeleteRecurringExpensePlanUseCase(
        ref.watch(recurringExpensePlanRepositoryProvider),
      ),
    );

final Provider<DeleteTransactionUseCase> deleteTransactionProvider =
    Provider<DeleteTransactionUseCase>(
      (ref) => DeleteTransactionUseCase(
        ref.watch(transactionRepositoryProvider),
        ref.watch(transactionDeletionRepositoryProvider),
      ),
    );

final Provider<CreateReceiptExpenseUseCase> createReceiptExpenseProvider =
    Provider<CreateReceiptExpenseUseCase>(
      (ref) => CreateReceiptExpenseUseCase(
        ref.watch(installmentTransactionRepositoryProvider),
        categoryValidator: ref.watch(transactionCategoryValidatorProvider),
      ),
    );

final Provider<ConvertExpenseToInstallmentsUseCase>
convertExpenseToInstallmentsProvider =
    Provider<ConvertExpenseToInstallmentsUseCase>(
      (ref) => ConvertExpenseToInstallmentsUseCase(
        ref.watch(transactionRepositoryProvider),
        ref.watch(installmentTransactionRepositoryProvider),
      ),
    );

final parseReceiptTextProvider = Provider<ParseReceiptTextUseCase>(
  (ref) => ParseReceiptTextUseCase(ref.watch(categoryRepositoryProvider)),
);

final scanReceiptProvider = Provider<ScanReceiptUseCase>(
  (ref) => ScanReceiptUseCase(
    ref.watch(receiptImagePickerProvider),
    ref.watch(receiptTextRecognizerProvider),
    ref.watch(parseReceiptTextProvider),
  ),
);

final Provider<CreateManualIncomeUseCase> createManualIncomeProvider =
    Provider<CreateManualIncomeUseCase>(
      (ref) => CreateManualIncomeUseCase(
        ref.watch(transactionRepositoryProvider),
        categoryValidator: ref.watch(transactionCategoryValidatorProvider),
      ),
    );

final Provider<CreateTransferUseCase> createTransferProvider =
    Provider<CreateTransferUseCase>(
      (ref) => CreateTransferUseCase(
        ref.watch(transactionRepositoryProvider),
        ref.watch(accountRepositoryProvider),
      ),
    );

final Provider<GetCategories> getCategoriesProvider = Provider<GetCategories>(
  (ref) => GetCategories(ref.watch(categoryRepositoryProvider)),
);

final Provider<GetCategory> getCategoryProvider = Provider<GetCategory>(
  (ref) => GetCategory(ref.watch(categoryRepositoryProvider)),
);

final Provider<CreateCategory> createCategoryProvider =
    Provider<CreateCategory>(
      (ref) => CreateCategory(ref.watch(categoryRepositoryProvider)),
    );

final Provider<UpdateCategory> updateCategoryProvider =
    Provider<UpdateCategory>(
      (ref) => UpdateCategory(ref.watch(categoryRepositoryProvider)),
    );

final Provider<DeleteCategory> deleteCategoryProvider =
    Provider<DeleteCategory>(
      (ref) => DeleteCategory(
        ref.watch(categoryRepositoryProvider),
        ref.watch(categoryUsageRepositoryProvider),
      ),
    );

final Provider<TransactionCategoryValidator>
transactionCategoryValidatorProvider = Provider<TransactionCategoryValidator>(
  (ref) => CategoryAssignmentValidator(ref.watch(categoryRepositoryProvider)),
);

final Provider<GetBudgetsUseCase> getBudgetsProvider =
    Provider<GetBudgetsUseCase>(
      (ref) => GetBudgetsUseCase(ref.watch(budgetRepositoryProvider)),
    );

final Provider<CreateBudgetUseCase> createBudgetProvider =
    Provider<CreateBudgetUseCase>(
      (ref) => CreateBudgetUseCase(
        ref.watch(budgetRepositoryProvider),
        ref.watch(categoryRepositoryProvider),
      ),
    );

final Provider<UpdateBudgetUseCase> updateBudgetProvider =
    Provider<UpdateBudgetUseCase>(
      (ref) => UpdateBudgetUseCase(
        ref.watch(budgetRepositoryProvider),
        ref.watch(categoryRepositoryProvider),
      ),
    );

final Provider<DeleteBudgetUseCase> deleteBudgetProvider =
    Provider<DeleteBudgetUseCase>(
      (ref) => DeleteBudgetUseCase(ref.watch(budgetRepositoryProvider)),
    );

final Provider<CalculateBudgetProgressUseCase> calculateBudgetProgressProvider =
    Provider<CalculateBudgetProgressUseCase>(
      (ref) => CalculateBudgetProgressUseCase(
        ref.watch(transactionRepositoryProvider),
      ),
    );
