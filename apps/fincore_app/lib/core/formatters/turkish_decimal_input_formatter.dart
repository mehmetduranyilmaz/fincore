import 'package:flutter/services.dart';

final class TurkishDecimalInputFormatter extends TextInputFormatter {
  const TurkishDecimalInputFormatter({
    this.allowNegative = false,
    this.decimalDigits = 2,
  });

  final bool allowNegative;
  final int decimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.trim();
    if (raw.isEmpty) return const TextEditingValue();
    final negative = allowNegative && raw.startsWith('-');
    final unsigned = raw.replaceAll('-', '');
    final commaIndex = unsigned.indexOf(',');
    final pastedDecimalPoint =
        oldValue.text.isEmpty &&
        commaIndex < 0 &&
        RegExp(r'^\d+\.\d{1,2}$').hasMatch(unsigned);
    final trailingDecimalPoint =
        commaIndex < 0 &&
        unsigned.endsWith('.') &&
        !oldValue.text.endsWith('.');
    final decimalPointIndex = commaIndex >= 0
        ? commaIndex
        : pastedDecimalPoint || trailingDecimalPoint
        ? unsigned.lastIndexOf('.')
        : -1;
    final integerSource = decimalPointIndex < 0
        ? unsigned
        : unsigned.substring(0, decimalPointIndex);
    final fractionSource = decimalPointIndex < 0
        ? ''
        : unsigned.substring(decimalPointIndex + 1);
    final integerDigits = integerSource.replaceAll(RegExp(r'\D'), '');
    final sanitizedFraction = fractionSource.replaceAll(RegExp(r'\D'), '');
    final fractionDigits = sanitizedFraction.substring(
      0,
      sanitizedFraction.length > decimalDigits
          ? decimalDigits
          : sanitizedFraction.length,
    );
    if (integerDigits.isEmpty && decimalPointIndex < 0) {
      return negative
          ? const TextEditingValue(
              text: '-',
              selection: TextSelection.collapsed(offset: 1),
            )
          : const TextEditingValue();
    }
    final grouped = _groupThousands(
      integerDigits.isEmpty ? '0' : _trimLeadingZeros(integerDigits),
    );
    final sign = negative ? '-' : '';
    final separator = decimalPointIndex >= 0 ? ',' : '';
    final formatted = '$sign$grouped$separator$fractionDigits';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _trimLeadingZeros(String value) {
    final trimmed = value.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return trimmed.isEmpty ? '0' : trimmed;
  }

  static String _groupThousands(String value) {
    final buffer = StringBuffer();
    for (var index = 0; index < value.length; index++) {
      final remaining = value.length - index;
      buffer.write(value[index]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }
}
