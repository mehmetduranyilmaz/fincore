import 'package:fincore_app/core/theme/app_durations.dart';
import 'package:fincore_app/core/theme/app_radius.dart';
import 'package:fincore_app/core/theme/app_shadows.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

final class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgBorderRadius,
        boxShadow: isDark ? AppShadows.darkCard : AppShadows.lightCard,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? content
            : Semantics(
                button: true,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: AppRadius.lgBorderRadius,
                  child: content,
                ),
              ),
      ),
    );
  }
}
