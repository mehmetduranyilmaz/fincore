import 'package:fincore_app/core/theme/app_durations.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/app_shell/presentation/pages/customers_page.dart';
import 'package:fincore_app/features/app_shell/presentation/pages/reports_page.dart';
import 'package:fincore_app/features/app_shell/presentation/pages/settings_page.dart';
import 'package:fincore_app/features/accounts/presentation/pages/accounts_page.dart';
import 'package:fincore_app/features/budgets/presentation/pages/budgets_page.dart';
import 'package:fincore_app/features/categories/presentation/pages/categories_page.dart';
import 'package:fincore_app/features/credit_cards/presentation/pages/credit_cards_page.dart';
import 'package:fincore_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:fincore_app/features/transactions/presentation/pages/transactions_page.dart';
import 'package:flutter/material.dart';

final class AppShellContent extends StatelessWidget {
  const AppShellContent({required this.destination, super.key});

  final AppShellDestination destination;

  @override
  Widget build(BuildContext context) {
    final content = switch (destination) {
      AppShellDestination.dashboard => const DashboardPage(),
      AppShellDestination.transactions => const TransactionsPage(),
      AppShellDestination.categories => const CategoriesPage(),
      AppShellDestination.budgets => const BudgetsPage(),
      AppShellDestination.customers => const CustomersPage(),
      AppShellDestination.accounts => const AccountsPage(),
      AppShellDestination.creditCards => const CreditCardsPage(),
      AppShellDestination.reports => const ReportsPage(),
      AppShellDestination.settings => const SettingsPage(),
    };

    return AnimatedSwitcher(
      duration: AppDurations.normal,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0.015, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(destination),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: content,
        ),
      ),
    );
  }
}
