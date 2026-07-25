import 'package:fincore_app/features/app_shell/presentation/controllers/app_shell_navigation_controller.dart';
import 'package:fincore_app/features/app_shell/presentation/widgets/app_shell_content.dart';
import 'package:fincore_app/features/app_shell/presentation/widgets/app_shell_destinations.dart';
import 'package:flutter/material.dart';

final class ExpandedAppShell extends StatelessWidget {
  const ExpandedAppShell({
    required this.destination,
    required this.onDestinationSelected,
    super.key,
  });

  final AppShellDestination destination;
  final ValueChanged<AppShellDestination> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = AppShellDestinations.indexOf(destination);

    return Row(
      children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          labelType: NavigationRailLabelType.all,
          onDestinationSelected: (index) {
            onDestinationSelected(
              AppShellDestinations.values[index].destination,
            );
          },
          destinations: [
            for (final item in AppShellDestinations.values)
              NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: AppShellContent(destination: destination)),
      ],
    );
  }
}
