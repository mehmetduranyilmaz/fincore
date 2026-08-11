import 'dart:async';

import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card.dart';
import 'package:fincore_app/features/credit_cards/domain/repositories/credit_card_repository.dart';
import 'package:fincore_app/features/credit_cards/presentation/controllers/credit_cards_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../credit_cards_test_data.dart';

void main() {
  test('moves from initial to loading and loaded', () async {
    final completer = Completer<List<CreditCard>>();
    final container = ProviderContainer(
      overrides: [
        creditCardRepositoryProvider.overrideWithValue(
          _CreditCardRepository(completer.future),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(creditCardsControllerProvider).status,
      CreditCardsStatus.initial,
    );

    final load = container.read(creditCardsControllerProvider.notifier).load();

    expect(
      container.read(creditCardsControllerProvider).status,
      CreditCardsStatus.loading,
    );

    final creditCards = createCreditCards();
    completer.complete(creditCards);
    await load;

    final state = container.read(creditCardsControllerProvider);

    expect(state.status, CreditCardsStatus.loaded);
    expect(state.creditCards.map((card) => card.bankName), [
      'Second Bank',
      'Test Bank',
    ]);
    expect(
      () => state.creditCards.add(creditCards.first),
      throwsUnsupportedError,
    );
    expect(state.errorMessage, isNull);
  });

  test('moves to failure when the repository throws', () async {
    final container = ProviderContainer(
      overrides: [
        creditCardRepositoryProvider.overrideWithValue(
          _CreditCardRepository(Future.error(Exception('Failed'))),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(creditCardsControllerProvider.notifier).load();

    final state = container.read(creditCardsControllerProvider);

    expect(state.status, CreditCardsStatus.failure);
    expect(state.creditCards, isEmpty);
    expect(state.errorMessage, isNotEmpty);
  });
}

final class _CreditCardRepository implements CreditCardRepository {
  const _CreditCardRepository(this.result);

  final Future<List<CreditCard>> result;

  @override
  Future<List<CreditCard>> getCreditCards() => result;
}
