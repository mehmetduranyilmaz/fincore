import 'package:fincore_app/features/app_shell/presentation/constants/app_shell_breakpoints.dart';
import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/app_shell/presentation/widgets/compact_app_shell.dart';
import 'package:fincore_app/features/app_shell/presentation/widgets/expanded_app_shell.dart';
import 'package:flutter/material.dart';

final class ResponsiveAppShell extends StatelessWidget {
  const ResponsiveAppShell({
    required this.destination,
    required this.onDestinationSelected,
    super.key,
  });

  final AppShellDestination destination;
  final ValueChanged<AppShellDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppShellBreakpoints.compact) {
          return CompactAppShell(
            destination: destination,
            onDestinationSelected: onDestinationSelected,
          );
        }

        return ExpandedAppShell(
          destination: destination,
          onDestinationSelected: onDestinationSelected,
        );
      },
    );
  }
}
