import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/dashboard/presentation/constants/dashboard_strings.dart';
import 'package:fincore_app/features/dashboard/presentation/providers/dashboard_summary_provider.dart';
import 'package:fincore_app/features/dashboard/presentation/widgets/dashboard_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);

    return summary.when(
      loading: () => const AppLoadingView(),
      error: (error, stackTrace) => AppErrorView(
        message: ErrorMapper.map(error),
        retryLabel: DashboardStrings.retry,
        onRetry: () => ref.invalidate(dashboardSummaryProvider),
      ),
      data: (value) => DashboardContent(summary: value),
    );
  }
}
