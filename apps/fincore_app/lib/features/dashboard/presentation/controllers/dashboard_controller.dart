import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:fincore_app/features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashboardStatus { initial, loading, loaded, failure }

final class DashboardState {
  const DashboardState._({
    required this.status,
    this.summary,
    this.errorMessage,
  });

  const DashboardState.initial() : this._(status: DashboardStatus.initial);

  const DashboardState.loading() : this._(status: DashboardStatus.loading);

  const DashboardState.loaded(DashboardSummary summary)
    : this._(status: DashboardStatus.loaded, summary: summary);

  const DashboardState.failure(String message)
    : this._(status: DashboardStatus.failure, errorMessage: message);

  final DashboardStatus status;
  final DashboardSummary? summary;
  final String? errorMessage;
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

final class DashboardController extends Notifier<DashboardState> {
  late GetDashboardSummary _getDashboardSummary;

  @override
  DashboardState build() {
    _getDashboardSummary = ref.watch(getDashboardSummaryProvider);
    return const DashboardState.initial();
  }

  Future<void> load() async {
    state = const DashboardState.loading();

    try {
      final summary = await _getDashboardSummary.execute();
      state = DashboardState.loaded(summary);
    } on Object catch (error) {
      state = DashboardState.failure(ErrorMapper.map(error));
    }
  }
}
