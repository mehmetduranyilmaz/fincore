import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/budgets/domain/usecases/delete_budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeleteBudgetStatus { initial, loading, success, failure }

final class DeleteBudgetState {
  const DeleteBudgetState._({
    required this.status,
    this.budgetId,
    this.errorMessage,
  });

  const DeleteBudgetState.initial()
    : this._(status: DeleteBudgetStatus.initial);

  const DeleteBudgetState.loading(String budgetId)
    : this._(status: DeleteBudgetStatus.loading, budgetId: budgetId);

  const DeleteBudgetState.success()
    : this._(status: DeleteBudgetStatus.success);

  const DeleteBudgetState.failure(String message)
    : this._(status: DeleteBudgetStatus.failure, errorMessage: message);

  final DeleteBudgetStatus status;
  final String? budgetId;
  final String? errorMessage;
}

final deleteBudgetControllerProvider =
    NotifierProvider<DeleteBudgetController, DeleteBudgetState>(
      DeleteBudgetController.new,
    );

final class DeleteBudgetController extends Notifier<DeleteBudgetState> {
  late DeleteBudgetUseCase _deleteBudget;

  @override
  DeleteBudgetState build() {
    _deleteBudget = ref.watch(deleteBudgetProvider);
    return const DeleteBudgetState.initial();
  }

  Future<void> delete(String budgetId) async {
    state = DeleteBudgetState.loading(budgetId);
    try {
      await _deleteBudget.execute(budgetId);
      await ref.read(appDataRefreshCoordinatorProvider).budgetChanged();
      state = const DeleteBudgetState.success();
    } on Object catch (error) {
      state = DeleteBudgetState.failure(ErrorMapper.map(error));
    }
  }
}
