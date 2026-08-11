import 'package:fincore_app/core/theme/app_colors.dart';
import 'package:fincore_app/core/theme/app_radius.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

final class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({required this.progress, super.key});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = progress >= 1
        ? colorScheme.error
        : progress >= 0.8
        ? AppColors.warning
        : colorScheme.primary;
    final percentage = (progress * 100).round();

    return Semantics(
      label: 'Bütçe kullanım oranı yüzde $percentage',
      value: '%$percentage',
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.pillBorderRadius,
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 10,
                color: color,
                backgroundColor: color.withValues(alpha: 0.16),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 48,
            child: Text(
              '%$percentage',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
