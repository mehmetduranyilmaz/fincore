import 'package:fincore_app/core/di/providers.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement.dart';
import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_statement_payment_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final creditCardStatementsProvider =
    FutureProvider.family<List<CreditCardStatement>, String>((
      ref,
      creditCardId,
    ) {
      return ref.watch(getCreditCardStatementsProvider).execute(creditCardId);
    });

typedef CreditCardStatementPaymentKey = ({
  String creditCardId,
  String statementId,
});

final creditCardStatementPaymentStatusProvider =
    FutureProvider.family<
      CreditCardStatementPaymentStatus,
      CreditCardStatementPaymentKey
    >((ref, key) {
      return ref
          .watch(getCreditCardStatementPaymentStatusProvider)
          .execute(
            creditCardId: key.creditCardId,
            statementId: key.statementId,
          );
    });
