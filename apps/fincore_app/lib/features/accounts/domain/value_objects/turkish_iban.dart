abstract final class TurkishIban {
  static String normalize(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static String format(String value) {
    final normalized = normalize(value);
    final groups = <String>[];
    for (var index = 0; index < normalized.length; index += 4) {
      final end = index + 4 < normalized.length ? index + 4 : normalized.length;
      groups.add(normalized.substring(index, end));
    }
    return groups.join(' ');
  }

  static bool isValid(String value) {
    final iban = normalize(value);
    if (!RegExp(r'^TR\d{24}$').hasMatch(iban)) return false;
    final rearranged = '${iban.substring(4)}${iban.substring(0, 4)}';
    var remainder = 0;
    for (final codeUnit in rearranged.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        remainder = (remainder * 10 + codeUnit - 48) % 97;
      } else {
        final letterValue = codeUnit - 55;
        remainder = (remainder * 100 + letterValue) % 97;
      }
    }
    return remainder == 1;
  }
}
