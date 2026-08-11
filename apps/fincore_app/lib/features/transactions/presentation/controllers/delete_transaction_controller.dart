import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeleteTransactionStatus { initial, loading, success, failure }

final class DeleteTransactionState {
  const DeleteTransactionState._({required this.status, this.errorMessage});

  const DeleteTransactionState.initial()
    : this._(status: DeleteTransactionStatus.initial);
  const DeleteTransactionState.loading()
    : this._(status: DeleteTransactionStatus.loading);
  const DeleteTransactionState.success()
    : this._(status: DeleteTransactionStatus.success);
  const DeleteTransactionState.failure(String message)
    : this._(status: DeleteTransactionStatus.failure, errorMessage: message);

  final DeleteTransactionStatus status;
  final String? errorMessage;
}

final deleteTransactionControllerProvider =
    NotifierProvider<DeleteTransactionController, DeleteTransactionState>(
      DeleteTransactionController.new,
    );

final class DeleteTransactionController
    extends Notifier<DeleteTransactionState> {
  late DeleteTransactionUseCase _deleteTransaction;

  @override
  DeleteTransactionState build() {
    _deleteTransaction = ref.watch(deleteTransactionProvider);
    return const DeleteTransactionState.initial();
  }

  Future<bool> delete(String transactionId) async {
    state = const DeleteTransactionState.loading();
    try {
      final deleted = await _deleteTransaction.execute(transactionId);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: const [], previous: deleted);
      state = const DeleteTransactionState.success();
      return true;
    } on Object catch (error) {
      state = DeleteTransactionState.failure(ErrorMapper.map(error));
      return false;
    }
  }
}
