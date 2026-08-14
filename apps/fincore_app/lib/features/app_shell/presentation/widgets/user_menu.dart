import 'dart:async';

import 'package:fincore_app/app/state/app_controller.dart';
import 'package:fincore_app/app/router/app_routes.dart';
import 'package:fincore_app/features/app_shell/presentation/constants/app_shell_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum UserMenuAction { profile, logout }

final class UserMenu extends ConsumerWidget {
  const UserMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<UserMenuAction>(
      tooltip: AppShellStrings.userMenu,
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (action) {
        switch (action) {
          case UserMenuAction.profile:
            context.push(AppRoutes.profile);
          case UserMenuAction.logout:
            unawaited(ref.read(appControllerProvider.notifier).logout());
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: UserMenuAction.profile,
          child: Text(AppShellStrings.profile),
        ),
        PopupMenuItem(
          value: UserMenuAction.logout,
          child: Text(AppShellStrings.logout),
        ),
      ],
    );
  }
}
