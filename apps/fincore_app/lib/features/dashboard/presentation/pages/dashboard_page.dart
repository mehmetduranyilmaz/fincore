import 'package:fincore_app/core/widgets/app_error_view.dart';
import 'package:fincore_app/core/widgets/app_loading_view.dart';
import 'package:fincore_app/features/dashboard/presentation/constants/dashboard_strings.dart';
import 'package:fincore_app/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:fincore_app/features/dashboard/presentation/widgets/dashboard_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

final class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(dashboardControllerProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);

    return switch (state.status) {
      DashboardStatus.initial ||
      DashboardStatus.loading => const AppLoadingView(),
      DashboardStatus.loaded => DashboardContent(summary: state.summary!),
      DashboardStatus.failure => AppErrorView(
        message: state.errorMessage ?? DashboardStrings.unableToLoad,
        retryLabel: DashboardStrings.retry,
        onRetry: ref.read(dashboardControllerProvider.notifier).load,
      ),
    };
  }
}
