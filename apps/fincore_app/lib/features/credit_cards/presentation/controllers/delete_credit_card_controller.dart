import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/delete_credit_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DeleteCreditCardStatus { initial, loading, success, failure }

final class DeleteCreditCardState {
  const DeleteCreditCardState._({
    required this.status,
    this.creditCardId,
    this.errorMessage,
  });

  const DeleteCreditCardState.initial()
    : this._(status: DeleteCreditCardStatus.initial);
  const DeleteCreditCardState.loading(String creditCardId)
    : this._(
        status: DeleteCreditCardStatus.loading,
        creditCardId: creditCardId,
      );
  const DeleteCreditCardState.success()
    : this._(status: DeleteCreditCardStatus.success);
  const DeleteCreditCardState.failure(String message)
    : this._(status: DeleteCreditCardStatus.failure, errorMessage: message);

  final DeleteCreditCardStatus status;
  final String? creditCardId;
  final String? errorMessage;
}

final deleteCreditCardControllerProvider =
    NotifierProvider<DeleteCreditCardController, DeleteCreditCardState>(
      DeleteCreditCardController.new,
    );

final class DeleteCreditCardController extends Notifier<DeleteCreditCardState> {
  late DeleteCreditCardUseCase _deleteCreditCard;

  @override
  DeleteCreditCardState build() {
    _deleteCreditCard = ref.watch(deleteCreditCardProvider);
    return const DeleteCreditCardState.initial();
  }

  Future<void> delete(String creditCardId) async {
    state = DeleteCreditCardState.loading(creditCardId);
    try {
      await _deleteCreditCard.execute(creditCardId);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .creditCardChanged(creditCardId);
      state = const DeleteCreditCardState.success();
    } on Object catch (error) {
      state = DeleteCreditCardState.failure(ErrorMapper.map(error));
    }
  }
}
