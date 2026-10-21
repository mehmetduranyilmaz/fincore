import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/usecases/reschedule_installments.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class InstallmentPlanSchedule {
  const InstallmentPlanSchedule({
    required this.installments,
    required this.reschedulableIds,
  });

  final List<Transaction> installments;
  final Set<String> reschedulableIds;
}

final installmentPlanScheduleProvider =
    FutureProvider.family<InstallmentPlanSchedule, String>((
      ref,
      installmentPlanId,
    ) async {
      final useCase = ref.watch(rescheduleInstallmentsProvider);
      final installments = await useCase.getPlan(installmentPlanId);
      return InstallmentPlanSchedule(
        installments: installments,
        reschedulableIds: await useCase.reschedulableIds(installments),
      );
    });

enum RescheduleInstallmentsStatus { initial, loading, success, failure }

final class RescheduleInstallmentsState {
  const RescheduleInstallmentsState._({
    required this.status,
    this.errorMessage,
  });

  const RescheduleInstallmentsState.initial()
    : this._(status: RescheduleInstallmentsStatus.initial);
  const RescheduleInstallmentsState.loading()
    : this._(status: RescheduleInstallmentsStatus.loading);
  const RescheduleInstallmentsState.success()
    : this._(status: RescheduleInstallmentsStatus.success);
  const RescheduleInstallmentsState.failure(String message)
    : this._(
        status: RescheduleInstallmentsStatus.failure,
        errorMessage: message,
      );

  final RescheduleInstallmentsStatus status;
  final String? errorMessage;
}

final rescheduleInstallmentsControllerProvider =
    NotifierProvider<
      RescheduleInstallmentsController,
      RescheduleInstallmentsState
    >(RescheduleInstallmentsController.new);

final class RescheduleInstallmentsController
    extends Notifier<RescheduleInstallmentsState> {
  late RescheduleInstallmentsUseCase _reschedule;

  @override
  RescheduleInstallmentsState build() {
    _reschedule = ref.watch(rescheduleInstallmentsProvider);
    return const RescheduleInstallmentsState.initial();
  }

  Future<void> reschedule(
    RescheduleInstallmentsInput input, {
    required List<Transaction> previous,
  }) async {
    state = const RescheduleInstallmentsState.loading();
    try {
      final changed = await _reschedule.execute(input);
      final changedIds = changed.map((item) => item.id).toSet();
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(
            current: changed,
            previous: previous.where((item) => changedIds.contains(item.id)),
          );
      ref.invalidate(installmentPlanScheduleProvider(input.installmentPlanId));
      state = const RescheduleInstallmentsState.success();
    } on Object catch (error) {
      state = RescheduleInstallmentsState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const RescheduleInstallmentsState.initial();
  }
}
