import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_manual_expense_input.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_manual_expense.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CreateExpenseStatus { initial, loading, success, failure }

final class CreateExpenseState {
  const CreateExpenseState._({required this.status, this.errorMessage});

  const CreateExpenseState.initial()
    : this._(status: CreateExpenseStatus.initial);

  const CreateExpenseState.loading()
    : this._(status: CreateExpenseStatus.loading);

  const CreateExpenseState.success()
    : this._(status: CreateExpenseStatus.success);

  const CreateExpenseState.failure(String message)
    : this._(status: CreateExpenseStatus.failure, errorMessage: message);

  final CreateExpenseStatus status;
  final String? errorMessage;
}

final createExpenseControllerProvider =
    NotifierProvider<CreateExpenseController, CreateExpenseState>(
      CreateExpenseController.new,
    );

final class CreateExpenseController extends Notifier<CreateExpenseState> {
  late CreateManualExpenseUseCase _createManualExpense;

  @override
  CreateExpenseState build() {
    _createManualExpense = ref.watch(createManualExpenseProvider);
    return const CreateExpenseState.initial();
  }

  Future<void> create(CreateManualExpenseInput input) async {
    state = const CreateExpenseState.loading();

    try {
      final transaction = await _createManualExpense.execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: [transaction]);
      state = const CreateExpenseState.success();
    } on Object catch (error) {
      state = CreateExpenseState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const CreateExpenseState.initial();
  }
}
