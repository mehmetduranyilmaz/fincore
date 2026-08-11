import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/budgets/domain/usecases/create_budget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CreateBudgetStatus { initial, loading, success, failure }

final class CreateBudgetState {
  const CreateBudgetState._({required this.status, this.errorMessage});

  const CreateBudgetState.initial()
    : this._(status: CreateBudgetStatus.initial);

  const CreateBudgetState.loading()
    : this._(status: CreateBudgetStatus.loading);

  const CreateBudgetState.success()
    : this._(status: CreateBudgetStatus.success);

  const CreateBudgetState.failure(String message)
    : this._(status: CreateBudgetStatus.failure, errorMessage: message);

  final CreateBudgetStatus status;
  final String? errorMessage;
}

final createBudgetControllerProvider =
    NotifierProvider<CreateBudgetController, CreateBudgetState>(
      CreateBudgetController.new,
    );

final class CreateBudgetController extends Notifier<CreateBudgetState> {
  late CreateBudgetUseCase _createBudget;

  @override
  CreateBudgetState build() {
    _createBudget = ref.watch(createBudgetProvider);
    return const CreateBudgetState.initial();
  }

  Future<void> create(CreateBudgetInput input) async {
    state = const CreateBudgetState.loading();
    try {
      await _createBudget.execute(input);
      await ref.read(appDataRefreshCoordinatorProvider).budgetChanged();
      state = const CreateBudgetState.success();
    } on Object catch (error) {
      state = CreateBudgetState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const CreateBudgetState.initial();
  }
}
