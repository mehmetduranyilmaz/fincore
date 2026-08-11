import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_receipt_expense_input.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_receipt_expense.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CreateReceiptExpenseStatus { initial, loading, success, failure }

final class CreateReceiptExpenseState {
  const CreateReceiptExpenseState._({required this.status, this.errorMessage});

  const CreateReceiptExpenseState.initial()
    : this._(status: CreateReceiptExpenseStatus.initial);
  const CreateReceiptExpenseState.loading()
    : this._(status: CreateReceiptExpenseStatus.loading);
  const CreateReceiptExpenseState.success()
    : this._(status: CreateReceiptExpenseStatus.success);
  const CreateReceiptExpenseState.failure(String message)
    : this._(status: CreateReceiptExpenseStatus.failure, errorMessage: message);

  final CreateReceiptExpenseStatus status;
  final String? errorMessage;
}

final createReceiptExpenseControllerProvider =
    NotifierProvider<CreateReceiptExpenseController, CreateReceiptExpenseState>(
      CreateReceiptExpenseController.new,
    );

final class CreateReceiptExpenseController
    extends Notifier<CreateReceiptExpenseState> {
  late CreateReceiptExpenseUseCase _createReceiptExpense;

  @override
  CreateReceiptExpenseState build() {
    _createReceiptExpense = ref.watch(createReceiptExpenseProvider);
    return const CreateReceiptExpenseState.initial();
  }

  Future<void> create(CreateReceiptExpenseInput input) async {
    state = const CreateReceiptExpenseState.loading();
    try {
      final transactions = await _createReceiptExpense.execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: transactions);
      state = const CreateReceiptExpenseState.success();
    } on Object catch (error) {
      state = CreateReceiptExpenseState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const CreateReceiptExpenseState.initial();
  }
}
