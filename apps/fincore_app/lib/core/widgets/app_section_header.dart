import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

final class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (action case final action?) ...[
          const SizedBox(width: AppSpacing.md),
          action,
        ],
      ],
    );
  }
}
