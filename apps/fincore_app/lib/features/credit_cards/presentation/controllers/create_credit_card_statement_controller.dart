import 'package:fincore_app/app/state/app_data_refresh_coordinator.dart';
import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/credit_cards/domain/errors/credit_card_operation_exception.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/create_credit_card_statement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CreateCreditCardStatementStatus { initial, loading, success, failure }

final class CreateCreditCardStatementState {
  const CreateCreditCardStatementState({
    this.status = CreateCreditCardStatementStatus.initial,
    this.errorMessage,
  });

  final CreateCreditCardStatementStatus status;
  final String? errorMessage;
}

final createCreditCardStatementControllerProvider =
    NotifierProvider<
      CreateCreditCardStatementController,
      CreateCreditCardStatementState
    >(CreateCreditCardStatementController.new);

final class CreateCreditCardStatementController
    extends Notifier<CreateCreditCardStatementState> {
  @override
  CreateCreditCardStatementState build() {
    return const CreateCreditCardStatementState();
  }

  Future<bool> create(CreateCreditCardStatementInput input) async {
    state = const CreateCreditCardStatementState(
      status: CreateCreditCardStatementStatus.loading,
    );
    try {
      await ref.read(createCreditCardStatementProvider).execute(input);
      ref
          .read(appDataRefreshCoordinatorProvider)
          .creditCardStatementChanged(input.creditCardId);
      state = const CreateCreditCardStatementState(
        status: CreateCreditCardStatementStatus.success,
      );
      return true;
    } on CreditCardOperationException catch (error) {
      state = CreateCreditCardStatementState(
        status: CreateCreditCardStatementStatus.failure,
        errorMessage: error.message,
      );
    } on Object catch (error) {
      state = CreateCreditCardStatementState(
        status: CreateCreditCardStatementStatus.failure,
        errorMessage: ErrorMapper.map(error),
      );
    }
    return false;
  }

  void reset() => state = const CreateCreditCardStatementState();
}
