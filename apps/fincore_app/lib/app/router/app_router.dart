import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/app/state/app_controller.dart';
import 'package:fincore_app/app/state/app_state.dart';
import 'package:fincore_app/features/accounts/presentation/pages/account_form_pages.dart';
import 'package:fincore_app/features/app_shell/presentation/pages/app_shell_page.dart';
import 'package:fincore_app/features/auth/presentation/pages/login_page.dart';
import 'package:fincore_app/features/auth/presentation/pages/profile_page.dart';
import 'package:fincore_app/features/budgets/presentation/pages/create_budget_page.dart';
import 'package:fincore_app/features/budgets/presentation/pages/edit_budget_page.dart';
import 'package:fincore_app/features/categories/presentation/pages/create_category_page.dart';
import 'package:fincore_app/features/categories/presentation/pages/edit_category_page.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/create_credit_card_page.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/create_credit_card_statement_page.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/credit_card_current_period_page.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/credit_card_future_installments_page.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/credit_card_payment_calendar_page.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/credit_card_statements_page.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/edit_credit_card_page.dart';
import 'package:fincore_app/features/customers/domain/entities/customer_payment_input.dart';
import 'package:fincore_app/features/customers/presentation/pages/create_customer_page.dart';
import 'package:fincore_app/features/customers/presentation/pages/credit_card_payment_page.dart';
import 'package:fincore_app/features/customers/presentation/pages/customer_payment_page.dart';
import 'package:fincore_app/features/customers/presentation/pages/customer_movements_page.dart';
import 'package:fincore_app/features/customers/presentation/pages/edit_customer_page.dart';
import 'package:fincore_app/features/splash/presentation/pages/splash_page.dart';
import 'package:fincore_app/features/transactions/presentation/pages/create_manual_expense_page.dart';
import 'package:fincore_app/features/transactions/presentation/pages/create_manual_income_page.dart';
import 'package:fincore_app/features/transactions/presentation/pages/create_receipt_expense_page.dart';
import 'package:fincore_app/features/transactions/presentation/pages/create_transfer_page.dart';
import 'package:fincore_app/features/transactions/presentation/pages/convert_installments_page.dart';
import 'package:fincore_app/features/transactions/presentation/pages/edit_transaction_page.dart';
import 'package:fincore_app/features/transactions/presentation/pages/transaction_details_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>(AppRouter.create);

abstract final class AppRouter {
  static GoRouter create(Ref ref) {
    final refreshNotifier = ValueNotifier<AppState>(
      ref.read(appControllerProvider),
    );

    ref.listen<AppState>(appControllerProvider, (previous, next) {
      refreshNotifier.value = next;
    });

    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      refreshListenable: refreshNotifier,
      redirect: (context, state) => _redirect(refreshNotifier.value, state),
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfilePage(),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const AppShellPage(),
        ),
        GoRoute(
          path: AppRoutes.createManualExpense,
          builder: (context, state) => const CreateManualExpensePage(),
        ),
        GoRoute(
          path: AppRoutes.createManualIncome,
          builder: (context, state) => const CreateManualIncomePage(),
        ),
        GoRoute(
          path: AppRoutes.createTransfer,
          builder: (context, state) => const CreateTransferPage(),
        ),
        GoRoute(
          path: AppRoutes.createReceiptExpense,
          builder: (context, state) => const CreateReceiptExpensePage(),
        ),
        GoRoute(
          path: AppRoutes.transactionDetails,
          builder: (context, state) => TransactionDetailsPage(
            transactionId: state.pathParameters['transactionId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.editTransaction,
          builder: (context, state) => EditTransactionPage(
            transactionId: state.pathParameters['transactionId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.convertTransactionInstallments,
          builder: (context, state) => ConvertInstallmentsPage(
            transactionId: state.pathParameters['transactionId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.createCategory,
          builder: (context, state) => const CreateCategoryPage(),
        ),
        GoRoute(
          path: AppRoutes.editCategory,
          builder: (context, state) =>
              EditCategoryPage(categoryId: state.pathParameters['categoryId']!),
        ),
        GoRoute(
          path: AppRoutes.createBudget,
          builder: (context, state) => const CreateBudgetPage(),
        ),
        GoRoute(
          path: AppRoutes.editBudget,
          builder: (context, state) =>
              EditBudgetPage(budgetId: state.pathParameters['budgetId']!),
        ),
        GoRoute(
          path: AppRoutes.createCreditCard,
          builder: (context, state) => const CreateCreditCardPage(),
        ),
        GoRoute(
          path: AppRoutes.editCreditCard,
          builder: (context, state) => EditCreditCardPage(
            creditCardId: state.pathParameters['creditCardId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.creditCardPayment,
          builder: (context, state) => CreditCardPaymentPage(
            creditCardId: state.pathParameters['creditCardId']!,
            statementId: state.uri.queryParameters['statementId'],
          ),
        ),
        GoRoute(
          path: AppRoutes.creditCardStatements,
          builder: (context, state) => CreditCardStatementsPage(
            creditCardId: state.pathParameters['creditCardId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.createCreditCardStatement,
          builder: (context, state) => CreateCreditCardStatementPage(
            creditCardId: state.pathParameters['creditCardId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.creditCardCurrentPeriod,
          builder: (context, state) => CreditCardCurrentPeriodPage(
            creditCardId: state.pathParameters['creditCardId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.creditCardFutureInstallments,
          builder: (context, state) => CreditCardFutureInstallmentsPage(
            creditCardId: state.pathParameters['creditCardId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.creditCardPaymentCalendar,
          builder: (context, state) => const CreditCardPaymentCalendarPage(),
        ),
        GoRoute(
          path: AppRoutes.createCustomer,
          builder: (context, state) => const CreateCustomerPage(),
        ),
        GoRoute(
          path: AppRoutes.editCustomer,
          builder: (context, state) =>
              EditCustomerPage(customerId: state.pathParameters['customerId']!),
        ),
        GoRoute(
          path: AppRoutes.customerPayment,
          builder: (context, state) => CustomerPaymentPage(
            customerId: state.pathParameters['customerId']!,
            direction: CustomerPaymentDirection.values.byName(
              state.pathParameters['direction']!,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.customerMovements,
          builder: (context, state) => CustomerMovementsPage(
            customerId: state.pathParameters['customerId']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.createAccount,
          builder: (context, state) => const CreateAccountPage(),
        ),
        GoRoute(
          path: AppRoutes.editAccount,
          builder: (context, state) =>
              EditAccountPage(accountId: state.pathParameters['accountId']!),
        ),
      ],
    );

    ref.onDispose(() {
      router.dispose();
      refreshNotifier.dispose();
    });

    return router;
  }

  static String? _redirect(AppState appState, GoRouterState routerState) {
    final location = routerState.matchedLocation;
    final isLogin = location == AppRoutes.login;
    final isSplash = location == AppRoutes.splash;

    return switch (appState.status) {
      AppStatus.initializing || AppStatus.failure => null,
      AppStatus.unauthenticated when !isLogin => AppRoutes.login,
      AppStatus.authenticated when isLogin || isSplash => AppRoutes.dashboard,
      _ => null,
    };
  }
}
