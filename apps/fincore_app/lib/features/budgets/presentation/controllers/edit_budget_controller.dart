import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/budgets/domain/usecases/update_budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EditBudgetStatus { initial, loading, success, failure }

final class EditBudgetState {
  const EditBudgetState._({required this.status, this.errorMessage});

  const EditBudgetState.initial() : this._(status: EditBudgetStatus.initial);

  const EditBudgetState.loading() : this._(status: EditBudgetStatus.loading);

  const EditBudgetState.success() : this._(status: EditBudgetStatus.success);

  const EditBudgetState.failure(String message)
    : this._(status: EditBudgetStatus.failure, errorMessage: message);

  final EditBudgetStatus status;
  final String? errorMessage;
}

final editBudgetControllerProvider =
    NotifierProvider<EditBudgetController, EditBudgetState>(
      EditBudgetController.new,
    );

final class EditBudgetController extends Notifier<EditBudgetState> {
  late UpdateBudgetUseCase _updateBudget;

  @override
  EditBudgetState build() {
    _updateBudget = ref.watch(updateBudgetProvider);
    return const EditBudgetState.initial();
  }

  Future<void> update(UpdateBudgetInput input) async {
    state = const EditBudgetState.loading();
    try {
      await _updateBudget.execute(input);
      await ref.read(appDataRefreshCoordinatorProvider).budgetChanged();
      state = const EditBudgetState.success();
    } on Object catch (error) {
      state = EditBudgetState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const EditBudgetState.initial();
  }
}
