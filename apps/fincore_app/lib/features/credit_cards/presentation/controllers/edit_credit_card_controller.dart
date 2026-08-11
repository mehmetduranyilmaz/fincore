import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/update_credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/errors/credit_card_operation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EditCreditCardStatus { initial, loading, success, failure }

final class EditCreditCardState {
  const EditCreditCardState._({required this.status, this.errorMessage});

  const EditCreditCardState.initial()
    : this._(status: EditCreditCardStatus.initial);
  const EditCreditCardState.loading()
    : this._(status: EditCreditCardStatus.loading);
  const EditCreditCardState.success()
    : this._(status: EditCreditCardStatus.success);
  const EditCreditCardState.failure(String message)
    : this._(status: EditCreditCardStatus.failure, errorMessage: message);

  final EditCreditCardStatus status;
  final String? errorMessage;
}

final editCreditCardControllerProvider =
    NotifierProvider<EditCreditCardController, EditCreditCardState>(
      EditCreditCardController.new,
    );

final class EditCreditCardController extends Notifier<EditCreditCardState> {
  late UpdateCreditCardUseCase _updateCreditCard;

  @override
  EditCreditCardState build() {
    _updateCreditCard = ref.watch(updateCreditCardProvider);
    return const EditCreditCardState.initial();
  }

  Future<void> update(UpdateCreditCardInput input) async {
    state = const EditCreditCardState.loading();
    try {
      final creditCard = await _updateCreditCard.execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .creditCardChanged(creditCard.id);
      state = const EditCreditCardState.success();
    } on CreditCardOperationException catch (error) {
      state = EditCreditCardState.failure(error.message);
    } on Object catch (error) {
      state = EditCreditCardState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const EditCreditCardState.initial();
  }
}
