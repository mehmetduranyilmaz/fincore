import 'package:fincore_app/features/app_shell/presentation/constants/app_shell_strings.dart';
import 'package:fincore_app/features/app_shell/presentation/widgets/coming_soon_view.dart';
import 'package:flutter/material.dart';

final class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonView(title: AppShellStrings.reports);
  }
}
