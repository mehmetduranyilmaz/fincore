import 'package:fincore_app/features/app_shell/presentation/constants/app_shell_strings.dart';
import 'package:fincore_app/features/app_shell/presentation/widgets/coming_soon_view.dart';
import 'package:flutter/material.dart';

final class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonView(title: AppShellStrings.accounts);
  }
}
