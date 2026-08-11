import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/transactions/domain/usecases/convert_expense_to_installments.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConvertInstallmentsStatus { initial, loading, success, failure }

final class ConvertInstallmentsState {
  const ConvertInstallmentsState._({required this.status, this.errorMessage});

  const ConvertInstallmentsState.initial()
    : this._(status: ConvertInstallmentsStatus.initial);
  const ConvertInstallmentsState.loading()
    : this._(status: ConvertInstallmentsStatus.loading);
  const ConvertInstallmentsState.success()
    : this._(status: ConvertInstallmentsStatus.success);
  const ConvertInstallmentsState.failure(String message)
    : this._(status: ConvertInstallmentsStatus.failure, errorMessage: message);

  final ConvertInstallmentsStatus status;
  final String? errorMessage;
}

final convertInstallmentsControllerProvider =
    NotifierProvider<ConvertInstallmentsController, ConvertInstallmentsState>(
      ConvertInstallmentsController.new,
    );

final class ConvertInstallmentsController
    extends Notifier<ConvertInstallmentsState> {
  late ConvertExpenseToInstallmentsUseCase _convert;

  @override
  ConvertInstallmentsState build() {
    _convert = ref.watch(convertExpenseToInstallmentsProvider);
    return const ConvertInstallmentsState.initial();
  }

  Future<void> convert(ConvertExpenseToInstallmentsInput input) async {
    state = const ConvertInstallmentsState.loading();
    try {
      final transactions = await _convert.execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: transactions);
      state = const ConvertInstallmentsState.success();
    } on Object catch (error) {
      state = ConvertInstallmentsState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const ConvertInstallmentsState.initial();
  }
}
