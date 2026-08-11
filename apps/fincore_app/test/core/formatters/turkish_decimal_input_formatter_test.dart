import 'package:fincore_app/core/formatters/turkish_decimal_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = TurkishDecimalInputFormatter();

  test('groups integer digits while typing', () {
    expect(_format(formatter, '', '1'), '1');
    expect(_format(formatter, '123', '1234'), '1.234');
    expect(_format(formatter, '1.234', '1.2345'), '12.345');
  });

  test('keeps at most two Turkish decimal digits', () {
    expect(_format(formatter, '1.234', '1.234,'), '1.234,');
    expect(_format(formatter, '1.234,5', '1.234,56'), '1.234,56');
    expect(_format(formatter, '1.234,56', '1.234,567'), '1.234,56');
  });

  test('supports negative balances only when enabled', () {
    const signed = TurkishDecimalInputFormatter(allowNegative: true);
    expect(_format(signed, '', '-1234,5'), '-1.234,5');
    expect(_format(formatter, '', '-1234,5'), '1.234,5');
  });
}

String _format(
  TurkishDecimalInputFormatter formatter,
  String oldText,
  String newText,
) {
  return formatter
      .formatEditUpdate(
        TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: oldText.length),
        ),
        TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        ),
      )
      .text;
}
