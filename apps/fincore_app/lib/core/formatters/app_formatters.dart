abstract final class AppFormatters {
  static String currency(
    double value, {
    String currencyCode = 'TRY',
    bool showPositiveSign = false,
  }) {
    final number = decimal(value, showPositiveSign: showPositiveSign);
    final currency = switch (currencyCode) {
      'TRY' => '₺',
      'USD' => '\$',
      'EUR' => '€',
      _ => currencyCode,
    };

    return '$number $currency';
  }

  static String decimal(double value, {bool showPositiveSign = false}) {
    final isNegative = value.isNegative;
    final absoluteParts = value.abs().toStringAsFixed(2).split('.');
    final integer = _groupThousands(absoluteParts.first);
    final decimals = absoluteParts.last;
    final sign = isNegative
        ? '-'
        : showPositiveSign && value > 0
        ? '+'
        : '';
    return '$sign$integer,$decimals';
  }

  static double? tryParseDecimal(String value) {
    final normalized = value
        .trim()
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  static String date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day.$month.${value.year}';
  }

  static String _groupThousands(String value) {
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final remaining = value.length - index;
      buffer.write(value[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}
