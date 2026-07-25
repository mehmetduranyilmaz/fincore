import 'package:fincore_app/features/app_shell/presentation/constants/app_shell_strings.dart';
import 'package:flutter/material.dart';

final class ComingSoonView extends StatelessWidget {
  const ComingSoonView({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const Text(AppShellStrings.comingSoon),
        ],
      ),
    );
  }
}
