import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/core/errors/error_mapper.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/usecases/get_credit_cards.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CreditCardsStatus { initial, loading, loaded, failure }

final class CreditCardsState {
  const CreditCardsState._({
    required this.status,
    this.creditCards = const [],
    this.errorMessage,
  });

  const CreditCardsState.initial() : this._(status: CreditCardsStatus.initial);

  const CreditCardsState.loading() : this._(status: CreditCardsStatus.loading);

  CreditCardsState.loaded(List<CreditCard> creditCards)
    : this._(
        status: CreditCardsStatus.loaded,
        creditCards: List.unmodifiable(creditCards),
      );

  const CreditCardsState.failure(String message)
    : this._(status: CreditCardsStatus.failure, errorMessage: message);

  final CreditCardsStatus status;
  final List<CreditCard> creditCards;
  final String? errorMessage;
}

final creditCardsControllerProvider =
    NotifierProvider<CreditCardsController, CreditCardsState>(
      CreditCardsController.new,
    );

final class CreditCardsController extends Notifier<CreditCardsState> {
  late GetCreditCards _getCreditCards;

  @override
  CreditCardsState build() {
    _getCreditCards = ref.watch(getCreditCardsProvider);
    return const CreditCardsState.initial();
  }

  Future<void> load() async {
    state = const CreditCardsState.loading();

    try {
      final creditCards = await _getCreditCards.execute();
      state = CreditCardsState.loaded(creditCards);
    } on Object catch (error) {
      state = CreditCardsState.failure(ErrorMapper.map(error));
    }
  }
}
