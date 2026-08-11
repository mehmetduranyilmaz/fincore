import 'package:fincore_app/features/transactions/domain/usecases/installment_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InstallmentCalculator', () {
    test('puts the rounding remainder on the final installment', () {
      expect(InstallmentCalculator.splitEvenly(100, 3), [33.33, 33.33, 33.34]);
    });

    test('accepts custom amounts only when their cents equal the total', () {
      expect(
        () => InstallmentCalculator.validateCustomAmounts(100, [30, 30, 40]),
        returnsNormally,
      );
      expect(
        () => InstallmentCalculator.validateCustomAmounts(100, [30, 30, 39.99]),
        throwsArgumentError,
      );
    });

    test('starts on purchase date and clamps short month dates', () {
      final purchaseDate = DateTime(2026, 1, 31);

      expect(
        InstallmentCalculator.installmentDate(purchaseDate, 0),
        DateTime(2026, 1, 31),
      );
      expect(
        InstallmentCalculator.installmentDate(purchaseDate, 1),
        DateTime(2026, 2, 28),
      );
      expect(
        InstallmentCalculator.installmentDate(purchaseDate, 2),
        DateTime(2026, 3, 31),
      );
    });
  });
}
