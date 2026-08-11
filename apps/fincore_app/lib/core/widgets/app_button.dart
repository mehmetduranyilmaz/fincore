import 'package:fincore_app/core/theme/app_durations.dart';
import 'package:flutter/material.dart';

final class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final callback = isEnabled && !isLoading ? onPressed : null;
    final content = AnimatedSwitcher(
      duration: AppDurations.fast,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: isLoading
          ? SizedBox.square(
              key: const ValueKey('loading'),
              dimension: 20,
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onPrimary,
                strokeWidth: 2,
              ),
            )
          : Text(label, key: const ValueKey('label')),
    );

    if (icon == null || isLoading) {
      return Semantics(
        button: true,
        enabled: callback != null,
        child: FilledButton(onPressed: callback, child: content),
      );
    }

    return Semantics(
      button: true,
      enabled: callback != null,
      child: FilledButton.icon(
        onPressed: callback,
        icon: Icon(icon),
        label: content,
      ),
    );
  }
}
