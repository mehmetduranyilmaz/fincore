import 'package:fincore_app/core/theme/app_spacing.dart';
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
        SafeArea(
          right: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final railHeight = constraints.maxHeight < 680
                  ? 680.0
                  : constraints.maxHeight;
              return SingleChildScrollView(
                child: SizedBox(
                  height: railHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: NavigationRail(
                      selectedIndex: selectedIndex,
                      labelType: NavigationRailLabelType.all,
                      groupAlignment: -0.85,
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
                  ),
                ),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: AppShellContent(destination: destination)),
      ],
    );
  }
}
