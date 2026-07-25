import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/app_shell/presentation/pages/accounts_page.dart';
import 'package:fincore_app/features/app_shell/presentation/pages/customers_page.dart';
import 'package:fincore_app/features/app_shell/presentation/pages/reports_page.dart';
import 'package:fincore_app/features/app_shell/presentation/pages/settings_page.dart';
import 'package:fincore_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:flutter/material.dart';

final class AppShellContent extends StatelessWidget {
  const AppShellContent({required this.destination, super.key});

  final AppShellDestination destination;

  @override
  Widget build(BuildContext context) {
    return switch (destination) {
      AppShellDestination.dashboard => const DashboardPage(),
      AppShellDestination.customers => const CustomersPage(),
      AppShellDestination.accounts => const AccountsPage(),
      AppShellDestination.reports => const ReportsPage(),
      AppShellDestination.settings => const SettingsPage(),
    };
  }
}
