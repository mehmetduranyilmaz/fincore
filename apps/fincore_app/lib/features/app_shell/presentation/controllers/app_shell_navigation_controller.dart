import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppShellDestination {
  dashboard,
  transactions,
  categories,
  budgets,
  customers,
  accounts,
  creditCards,
  reports,
  settings,
}

final appShellNavigationControllerProvider =
    NotifierProvider<AppShellNavigationController, AppShellDestination>(
      AppShellNavigationController.new,
    );

final class AppShellNavigationController extends Notifier<AppShellDestination> {
  @override
  AppShellDestination build() => AppShellDestination.dashboard;

  void select(AppShellDestination destination) {
    state = destination;
  }
}
