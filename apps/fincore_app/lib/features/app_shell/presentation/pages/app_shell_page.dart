import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/features/app_shell/presentation/constants/app_shell_strings.dart';
import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/app_shell/presentation/widgets/responsive_app_shell.dart';
import 'package:fincore_app/features/app_shell/presentation/widgets/user_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class AppShellPage extends ConsumerWidget {
  const AppShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(appShellNavigationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(AppShellStrings.appName),
          ],
        ),
        actions: const [UserMenu()],
      ),
      body: ResponsiveAppShell(
        destination: destination,
        onDestinationSelected: ref
            .read(appShellNavigationControllerProvider.notifier)
            .select,
      ),
    );
  }
}
