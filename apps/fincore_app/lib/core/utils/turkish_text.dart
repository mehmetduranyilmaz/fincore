abstract final class TurkishText {
  static const String _alphabet = 'abcçdefgğhıijklmnoöprsştuüvyz';

  static String normalize(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('I', 'ı')
        .replaceAll('İ', 'i')
        .toLowerCase();
  }

  static int compare(String left, String right) {
    final a = normalize(left);
    final b = normalize(right);
    final length = a.length < b.length ? a.length : b.length;
    for (var index = 0; index < length; index++) {
      final aRank = _rank(a[index]);
      final bRank = _rank(b[index]);
      if (aRank != bRank) return aRank.compareTo(bRank);
    }
    return a.length.compareTo(b.length);
  }

  static int _rank(String character) {
    final index = _alphabet.indexOf(character);
    return index < 0 ? 1000 + character.codeUnitAt(0) : index;
  }
}
