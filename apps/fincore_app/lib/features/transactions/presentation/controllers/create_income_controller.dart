import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_manual_income_input.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_manual_income.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CreateIncomeStatus { initial, loading, success, failure }

final class CreateIncomeState {
  const CreateIncomeState._({required this.status, this.errorMessage});

  const CreateIncomeState.initial()
    : this._(status: CreateIncomeStatus.initial);

  const CreateIncomeState.loading()
    : this._(status: CreateIncomeStatus.loading);

  const CreateIncomeState.success()
    : this._(status: CreateIncomeStatus.success);

  const CreateIncomeState.failure(String message)
    : this._(status: CreateIncomeStatus.failure, errorMessage: message);

  final CreateIncomeStatus status;
  final String? errorMessage;
}

final createIncomeControllerProvider =
    NotifierProvider<CreateIncomeController, CreateIncomeState>(
      CreateIncomeController.new,
    );

final class CreateIncomeController extends Notifier<CreateIncomeState> {
  late CreateManualIncomeUseCase _createManualIncome;

  @override
  CreateIncomeState build() {
    _createManualIncome = ref.watch(createManualIncomeProvider);
    return const CreateIncomeState.initial();
  }

  Future<void> create(CreateManualIncomeInput input) async {
    state = const CreateIncomeState.loading();

    try {
      final transaction = await _createManualIncome.execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: [transaction]);
      state = const CreateIncomeState.success();
    } on Object catch (error) {
      state = CreateIncomeState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const CreateIncomeState.initial();
  }
}
