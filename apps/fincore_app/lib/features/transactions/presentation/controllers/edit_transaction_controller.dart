import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/transactions/domain/entities/update_transaction_input.dart';
import 'package:fincore_app/features/transactions/domain/usecases/update_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EditTransactionStatus { initial, loading, success, failure }

final class EditTransactionState {
  const EditTransactionState._({
    required this.status,
    this.transaction,
    this.errorMessage,
  });

  const EditTransactionState.initial()
    : this._(status: EditTransactionStatus.initial);

  const EditTransactionState.loading()
    : this._(status: EditTransactionStatus.loading);

  const EditTransactionState.success(Transaction transaction)
    : this._(status: EditTransactionStatus.success, transaction: transaction);

  const EditTransactionState.failure(String message)
    : this._(status: EditTransactionStatus.failure, errorMessage: message);

  final EditTransactionStatus status;
  final Transaction? transaction;
  final String? errorMessage;
}

final editTransactionControllerProvider =
    NotifierProvider<EditTransactionController, EditTransactionState>(
      EditTransactionController.new,
    );

final class EditTransactionController extends Notifier<EditTransactionState> {
  late UpdateTransactionUseCase _updateTransaction;

  @override
  EditTransactionState build() {
    _updateTransaction = ref.watch(updateTransactionProvider);
    return const EditTransactionState.initial();
  }

  Future<void> update(UpdateTransactionInput input) async {
    state = const EditTransactionState.loading();

    try {
      final previous = await ref
          .read(transactionRepositoryProvider)
          .getById(input.transactionId);
      final transaction = await _updateTransaction.execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: [transaction], previous: [?previous]);
      state = EditTransactionState.success(transaction);
    } on Object catch (error) {
      state = EditTransactionState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const EditTransactionState.initial();
  }
}
