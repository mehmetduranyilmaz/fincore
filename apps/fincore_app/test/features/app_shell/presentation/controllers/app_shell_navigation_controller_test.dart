import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts on dashboard and selects a destination', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(appShellNavigationControllerProvider),
      AppShellDestination.dashboard,
    );

    container
        .read(appShellNavigationControllerProvider.notifier)
        .select(AppShellDestination.customers);

    expect(
      container.read(appShellNavigationControllerProvider),
      AppShellDestination.customers,
    );
  });
}
