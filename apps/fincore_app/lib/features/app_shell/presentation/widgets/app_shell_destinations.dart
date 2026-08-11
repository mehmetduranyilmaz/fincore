import 'package:fincore_app/features/app_shell/presentation/constants/app_shell_strings.dart';
import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:flutter/material.dart';

final class AppShellDestinationData {
  const AppShellDestinationData({
    required this.destination,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final AppShellDestination destination;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

abstract final class AppShellDestinations {
  static const List<AppShellDestinationData> values = [
    AppShellDestinationData(
      destination: AppShellDestination.dashboard,
      label: AppShellStrings.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    AppShellDestinationData(
      destination: AppShellDestination.transactions,
      label: AppShellStrings.transactions,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    AppShellDestinationData(
      destination: AppShellDestination.categories,
      label: AppShellStrings.categories,
      icon: Icons.category_outlined,
      selectedIcon: Icons.category,
    ),
    AppShellDestinationData(
      destination: AppShellDestination.budgets,
      label: AppShellStrings.budgets,
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings,
    ),
    AppShellDestinationData(
      destination: AppShellDestination.customers,
      label: AppShellStrings.customers,
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    AppShellDestinationData(
      destination: AppShellDestination.accounts,
      label: AppShellStrings.accounts,
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    AppShellDestinationData(
      destination: AppShellDestination.creditCards,
      label: AppShellStrings.creditCards,
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card,
    ),
    AppShellDestinationData(
      destination: AppShellDestination.reports,
      label: AppShellStrings.reports,
      icon: Icons.assessment_outlined,
      selectedIcon: Icons.assessment,
    ),
    AppShellDestinationData(
      destination: AppShellDestination.settings,
      label: AppShellStrings.settings,
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  static int indexOf(AppShellDestination destination) {
    return values.indexWhere((item) => item.destination == destination);
  }
}
