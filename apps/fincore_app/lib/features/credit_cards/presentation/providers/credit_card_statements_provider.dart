import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final creditCardStatementsProvider =
    FutureProvider.family<List<CreditCardStatement>, String>((
      ref,
      creditCardId,
    ) {
      return ref.watch(getCreditCardStatementsProvider).execute(creditCardId);
    });
