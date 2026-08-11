import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_activity_summary.dart';
import 'package:fincore_app/features/transactions/domain/entities/transaction.dart';
import 'package:fincore_app/features/credit_cards/presentation/providers/credit_card_balance_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final creditCardActivitySummaryProvider =
    FutureProvider.family<CreditCardActivitySummary, String>((
      ref,
      creditCardId,
    ) async {
      final creditCard = await ref.watch(
        creditCardProvider(creditCardId).future,
      );
      if (creditCard == null) {
        throw StateError('Credit card not found.');
      }
      return ref
          .watch(getCreditCardActivitySummaryProvider)
          .execute(creditCard);
    });

final creditCardCurrentPeriodTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((ref, creditCardId) {
      return ref
          .watch(getCreditCardCurrentPeriodTransactionsProvider)
          .execute(creditCardId);
    });

final creditCardFutureInstallmentsProvider =
    FutureProvider.family<List<Transaction>, String>((ref, creditCardId) async {
      final creditCard = await ref.watch(
        creditCardProvider(creditCardId).future,
      );
      if (creditCard == null) {
        throw StateError('Credit card not found.');
      }
      return ref
          .watch(getCreditCardFutureInstallmentsProvider)
          .execute(creditCard);
    });
