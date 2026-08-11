import 'package:fincore_app/core/theme/app_durations.dart';
import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/app_shell/presentation/widgets/app_shell_content.dart';
import 'package:fincore_app/features/app_shell/presentation/widgets/app_shell_destinations.dart';
import 'package:flutter/material.dart';

final class CompactAppShell extends StatelessWidget {
  const CompactAppShell({
    required this.destination,
    required this.onDestinationSelected,
    super.key,
  });

  final AppShellDestination destination;
  final ValueChanged<AppShellDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = AppShellDestinations.indexOf(destination);

    return Column(
      children: [
        Expanded(child: AppShellContent(destination: destination)),
        AnimatedContainer(
          duration: AppDurations.normal,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: selectedIndex,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: (index) {
                onDestinationSelected(
                  AppShellDestinations.values[index].destination,
                );
              },
              destinations: [
                for (final item in AppShellDestinations.values)
                  NavigationDestination(
                    tooltip: item.label,
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
