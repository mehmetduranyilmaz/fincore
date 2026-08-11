import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/create_credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/errors/credit_card_operation_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CreateCreditCardStatus { initial, loading, success, failure }

final class CreateCreditCardState {
  const CreateCreditCardState._({required this.status, this.errorMessage});

  const CreateCreditCardState.initial()
    : this._(status: CreateCreditCardStatus.initial);
  const CreateCreditCardState.loading()
    : this._(status: CreateCreditCardStatus.loading);
  const CreateCreditCardState.success()
    : this._(status: CreateCreditCardStatus.success);
  const CreateCreditCardState.failure(String message)
    : this._(status: CreateCreditCardStatus.failure, errorMessage: message);

  final CreateCreditCardStatus status;
  final String? errorMessage;
}

final createCreditCardControllerProvider =
    NotifierProvider<CreateCreditCardController, CreateCreditCardState>(
      CreateCreditCardController.new,
    );

final class CreateCreditCardController extends Notifier<CreateCreditCardState> {
  late CreateCreditCardUseCase _createCreditCard;

  @override
  CreateCreditCardState build() {
    _createCreditCard = ref.watch(createCreditCardProvider);
    return const CreateCreditCardState.initial();
  }

  Future<void> create(CreateCreditCardInput input) async {
    state = const CreateCreditCardState.loading();
    try {
      final creditCard = await _createCreditCard.execute(input);
      await ref
          .read(appDataRefreshCoordinatorProvider)
          .creditCardChanged(creditCard.id);
      state = const CreateCreditCardState.success();
    } on CreditCardOperationException catch (error) {
      state = CreateCreditCardState.failure(error.message);
    } on Object catch (error) {
      state = CreateCreditCardState.failure(ErrorMapper.map(error));
    }
  }

  void reset() {
    state = const CreateCreditCardState.initial();
  }
}
