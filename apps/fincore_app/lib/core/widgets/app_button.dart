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
    final content = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.onPrimary,
              strokeWidth: 2,
            ),
          )
        : Text(label);

    if (icon == null || isLoading) {
      return FilledButton(onPressed: callback, child: content);
    }

    return FilledButton.icon(
      onPressed: callback,
      icon: Icon(icon),
      label: content,
    );
  }
}
