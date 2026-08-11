import 'package:fincore_app/core/theme/app_durations.dart';
import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

final class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: AppDurations.normal,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: Center(
        child: Semantics(
          label: 'Yükleniyor',
          child: const SizedBox.square(
            dimension: AppSpacing.xl,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      ),
    );
  }
}
