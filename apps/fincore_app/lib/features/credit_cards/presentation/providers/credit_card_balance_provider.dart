import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_balance.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final creditCardBalanceProvider =
    FutureProvider.family<CreditCardBalance, String>((ref, creditCardId) {
      return ref
          .watch(calculateCreditCardBalanceProvider)
          .execute(creditCardId);
    });

final creditCardProvider = FutureProvider.family((
  ref,
  String creditCardId,
) async {
  final cards = await ref.watch(creditCardRepositoryProvider).getCreditCards();
  for (final card in cards) {
    if (card.id == creditCardId) return card;
  }
  return null;
});
