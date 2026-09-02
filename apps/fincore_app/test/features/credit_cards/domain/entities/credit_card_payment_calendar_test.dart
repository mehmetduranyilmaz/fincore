import 'package:fincore_app/features/credit_cards/domain/entities/credit_card_payment_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scenario in <(double, double, double)>[
    (0, 0, 100),
    (50, 0.5, 50),
    (100, 1, 0),
    (125, 1, 0),
  ]) {
    test('payment progress clamps paid amount ${scenario.$1}', () {
      final month = CreditCardPaymentMonth(
        year: 2026,
        month: 8,
        totalsByCurrency: const {'TRY': 100},
        paidByCurrency: {'TRY': scenario.$1},
        transactionCount: 1,
      );

      expect(month.completionRatio, scenario.$2);
      expect(month.remainingByCurrency, {'TRY': scenario.$3});
      expect(month.isPaid, scenario.$2 == 1);
    });
  }
}
