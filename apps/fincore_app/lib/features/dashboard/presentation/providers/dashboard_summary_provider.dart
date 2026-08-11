import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) {
  return ref.watch(calculateDashboardSummaryProvider).execute();
});
