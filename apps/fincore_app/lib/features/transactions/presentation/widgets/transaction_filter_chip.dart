import 'package:flutter/material.dart';

final class TransactionFilterChip extends StatelessWidget {
  const TransactionFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return FilterChip(
      avatar: avatar == null
          ? null
          : IconTheme(
              data: IconThemeData(color: foreground, size: 18),
              child: avatar!,
            ),
      label: Text(label),
      labelStyle: TextStyle(
        color: foreground,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      selected: selected,
      selectedColor: colorScheme.secondaryContainer,
      backgroundColor: colorScheme.surfaceContainerLow,
      checkmarkColor: colorScheme.onSecondaryContainer,
      side: BorderSide(
        color: selected
            ? colorScheme.secondary.withValues(alpha: 0.45)
            : colorScheme.outlineVariant,
      ),
      onSelected: onSelected,
    );
  }
}
