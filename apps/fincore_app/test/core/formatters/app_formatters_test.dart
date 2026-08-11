import 'package:fincore_app/core/formatters/app_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFormatters.currency', () {
    test('formats TRY values with Turkish separators', () {
      expect(AppFormatters.currency(1250), '1.250,00 ₺');
      expect(AppFormatters.currency(12450.75), '12.450,75 ₺');
      expect(AppFormatters.currency(250000), '250.000,00 ₺');
    });

    test('formats signs and supported currency symbols', () {
      expect(AppFormatters.currency(-1250.5), '-1.250,50 ₺');
      expect(
        AppFormatters.currency(1250, showPositiveSign: true),
        '+1.250,00 ₺',
      );
      expect(AppFormatters.currency(750, currencyCode: 'USD'), '750,00 \$');
    });
  });

  test('formats dates with Turkish numeric order', () {
    expect(AppFormatters.date(DateTime(2026, 7, 5)), '05.07.2026');
  });

  test('parses Turkish decimal input', () {
    expect(AppFormatters.tryParseDecimal('8.000,50'), 8000.5);
    expect(AppFormatters.tryParseDecimal(' 1.250,00 '), 1250);
    expect(AppFormatters.tryParseDecimal('geçersiz'), isNull);
  });
}
