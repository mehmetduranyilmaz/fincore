import 'package:fincore_app/features/accounts/domain/value_objects/turkish_iban.dart';
import 'package:flutter/services.dart';

final class TurkishIbanInputFormatter extends TextInputFormatter {
  const TurkishIbanInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = TurkishIban.normalize(newValue.text);
    final limited = normalized.length > 26
        ? normalized.substring(0, 26)
        : normalized;
    final formatted = TurkishIban.format(limited);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
