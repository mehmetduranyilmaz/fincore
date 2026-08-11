import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/transactions/domain/entities/create_transfer_input.dart';
import 'package:fincore_app/features/transactions/domain/usecases/create_transfer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CreateTransferStatus { initial, loading, success, failure }

final class CreateTransferState {
  const CreateTransferState._({required this.status, this.errorMessage});

  const CreateTransferState.initial()
    : this._(status: CreateTransferStatus.initial);

  const CreateTransferState.loading()
    : this._(status: CreateTransferStatus.loading);

  const CreateTransferState.success()
    : this._(status: CreateTransferStatus.success);

  const CreateTransferState.failure(String message)
    : this._(status: CreateTransferStatus.failure, errorMessage: message);

  final CreateTransferStatus status;
  final String? errorMessage;
}

final createTransferControllerProvider =
    NotifierProvider<CreateTransferController, CreateTransferState>(
      CreateTransferController.new,
    );

final class CreateTransferController extends Notifier<CreateTransferState> {
  late CreateTransferUseCase _createTransfer;

  @override
  CreateTransferState build() {
    _createTransfer = ref.watch(createTransferProvider);
    return const CreateTransferState.initial();
  }

  Future<void> create(CreateTransferInput input) async {
    state = const CreateTransferState.loading();

    try {
      final transactions = await _createTransfer.execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .transactionsChanged(current: transactions);
      state = const CreateTransferState.success();
    } on Object catch (error) {
      state = CreateTransferState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const CreateTransferState.initial();
  }
}
