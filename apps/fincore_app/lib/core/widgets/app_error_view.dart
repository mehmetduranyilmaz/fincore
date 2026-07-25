import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

final class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Retry',
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: retryLabel, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
