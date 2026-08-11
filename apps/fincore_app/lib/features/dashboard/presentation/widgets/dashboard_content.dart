import 'package:fincore_app/core/theme/app_spacing.dart';
import 'package:fincore_app/core/widgets/app_section_header.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/dashboard/presentation/constants/dashboard_breakpoints.dart';
import 'package:fincore_app/features/dashboard/presentation/constants/dashboard_strings.dart';
import 'package:fincore_app/features/dashboard/presentation/widgets/balance_summary_card.dart';
import 'package:flutter/material.dart';

final class DashboardContent extends StatelessWidget {
  const DashboardContent({required this.summary, super.key});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < DashboardBreakpoints.desktop) {
          return _MobileDashboard(summary: summary);
        }

        return _DesktopDashboard(summary: summary);
      },
    );
  }
}

final class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('dashboard_mobile_layout'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(title: DashboardStrings.title),
          const SizedBox(height: AppSpacing.md),
          BalanceSummaryCard(summary: summary),
        ],
      ),
    );
  }
}

final class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('dashboard_desktop_layout'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSectionHeader(title: DashboardStrings.title),
              const SizedBox(height: AppSpacing.lg),
              BalanceSummaryCard(summary: summary),
            ],
          ),
        ),
      ),
    );
  }
}
