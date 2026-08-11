import 'package:fincore_app/features/categories/domain/entities/category.dart';
import 'package:fincore_app/features/categories/domain/entities/category_type.dart';
import 'package:fincore_app/features/categories/domain/repositories/category_repository.dart';
import 'package:fincore_app/features/transactions/domain/entities/receipt_scan_draft.dart';

final class ParseReceiptTextUseCase {
  const ParseReceiptTextUseCase(this._categoryRepository);

  final CategoryRepository _categoryRepository;

  Future<ReceiptScanDraft> execute(String rawText) async {
    final normalizedText = _normalizeTurkish(rawText).toUpperCase();
    final categories = await _categoryRepository.getAll();
    return ReceiptScanDraft(
      rawText: rawText,
      totalAmount: _extractTotal(rawText),
      description: _extractMerchant(rawText),
      transactionDate: _extractDate(rawText),
      lastFourDigits: _extractLastFourDigits(normalizedText),
      installmentCount: _extractInstallmentCount(normalizedText),
      suggestedCategoryId: _suggestCategory(normalizedText, categories),
    );
  }

  static double? _extractTotal(String text) {
    final candidates = <double>[];
    final prioritized = RegExp(
      r'(?:GENEL\s*TOPLAM|TOPLAM|TOTAL|TUTAR)[^\d]{0,20}'
      r'(\d[\d.\s]*[,.]\d{2})',
      caseSensitive: false,
    );
    for (final match in prioritized.allMatches(text)) {
      final value = _parseMoney(match.group(1));
      if (value != null) {
        candidates.add(value);
      }
    }
    if (candidates.isNotEmpty) {
      return candidates.reduce((left, right) => left > right ? left : right);
    }

    final fallback = RegExp(r'\b(\d[\d.\s]*[,.]\d{2})\s*(?:TL|TRY|₺)\b');
    for (final match in fallback.allMatches(text.toUpperCase())) {
      final value = _parseMoney(match.group(1));
      if (value != null) {
        candidates.add(value);
      }
    }
    return candidates.isEmpty
        ? null
        : candidates.reduce((left, right) => left > right ? left : right);
  }

  static double? _parseMoney(String? value) {
    if (value == null) {
      return null;
    }
    final compact = value.replaceAll(RegExp(r'\s'), '');
    final decimalSeparatorIndex = [
      compact.lastIndexOf(','),
      compact.lastIndexOf('.'),
    ].reduce((left, right) => left > right ? left : right);
    if (decimalSeparatorIndex < 0 ||
        compact.length - decimalSeparatorIndex - 1 != 2) {
      return null;
    }
    final integerPart = compact
        .substring(0, decimalSeparatorIndex)
        .replaceAll(RegExp(r'[^\d]'), '');
    final decimalPart = compact
        .substring(decimalSeparatorIndex + 1)
        .replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse('$integerPart.$decimalPart');
  }

  static DateTime? _extractDate(String text) {
    final dayFirst = RegExp(
      r'\b(0?[1-9]|[12]\d|3[01])[./-](0?[1-9]|1[0-2])[./-](20\d{2})\b',
    ).firstMatch(text);
    if (dayFirst != null) {
      return _safeDate(
        int.parse(dayFirst.group(3)!),
        int.parse(dayFirst.group(2)!),
        int.parse(dayFirst.group(1)!),
      );
    }

    final yearFirst = RegExp(
      r'\b(20\d{2})[./-](0?[1-9]|1[0-2])[./-](0?[1-9]|[12]\d|3[01])\b',
    ).firstMatch(text);
    if (yearFirst == null) {
      return null;
    }
    return _safeDate(
      int.parse(yearFirst.group(1)!),
      int.parse(yearFirst.group(2)!),
      int.parse(yearFirst.group(3)!),
    );
  }

  static DateTime? _safeDate(int year, int month, int day) {
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  static String? _extractLastFourDigits(String text) {
    final patterns = [
      RegExp(r'(?:SON\s*4|KART\s*(?:NO|NUMARASI)?)[^\d]{0,12}(\d{4})'),
      RegExp(r'(?:\*{4,}|X{4,})\s*(\d{4})'),
      RegExp(r'\b\d{4}\s*(?:\*{4,}|X{4,})\s*(\d{4})\b'),
    ];
    for (final pattern in patterns) {
      final value = pattern.firstMatch(text)?.group(1);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static int? _extractInstallmentCount(String text) {
    final patterns = [
      RegExp(r'\b(\d{1,2})\s*TAKSIT\b'),
      RegExp(r'\bTAKSIT\s*(?:SAYISI)?[^\d]{0,8}(\d{1,2})\b'),
    ];
    for (final pattern in patterns) {
      final rawValue = pattern.firstMatch(text)?.group(1);
      final value = rawValue == null ? null : int.tryParse(rawValue);
      if (value != null && value >= 2 && value <= 36) {
        return value;
      }
    }
    return null;
  }

  static String? _extractMerchant(String text) {
    final excluded = RegExp(
      r'(TARIH|DATE|SAAT|FIS|FİS|FATURA|VERGI|VERGİ|TOPLAM|TOTAL|TUTAR|'
      r'TERMINAL|TERMİNAL|POS|KDV|MALIYE|MALİYE|TESEKKUR|TEŞEKKÜR)',
      caseSensitive: false,
    );
    for (final line in text.split(RegExp(r'[\r\n]+'))) {
      final value = line.trim();
      if (value.length >= 3 &&
          value.length <= 80 &&
          RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(value) &&
          !excluded.hasMatch(value)) {
        return value;
      }
    }
    return null;
  }

  static String? _suggestCategory(
    String normalizedText,
    List<Category> categories,
  ) {
    const keywords = <String, List<String>>{
      'category-grocery': [
        'MARKET',
        'MIGROS',
        'A101',
        'BIM',
        'SOK',
        'CARREFOUR',
      ],
      'category-transport': [
        'PETROL',
        'SHELL',
        'OPET',
        'BENZIN',
        'OTOPARK',
        'TAKSI',
      ],
      'category-subscription': ['NETFLIX', 'SPOTIFY', 'ABONELIK'],
      'category-entertainment': ['SINEMA', 'STEAM', 'OYUN', 'TIYATRO'],
      'category-utilities': ['ELEKTRIK', 'DOGALGAZ', 'INTERNET', 'TELEKOM'],
      'category-food': ['RESTORAN', 'CAFE', 'KAFE', 'YEMEK', 'LOKANTA'],
      'category-rent': ['KIRA'],
    };
    final availableIds = categories
        .where((category) => category.type == CategoryType.expense)
        .map((category) => category.id)
        .toSet();
    for (final entry in keywords.entries) {
      if (availableIds.contains(entry.key) &&
          entry.value.any(normalizedText.contains)) {
        return entry.key;
      }
    }
    return null;
  }

  static String _normalizeTurkish(String value) {
    return value
        .replaceAll('İ', 'I')
        .replaceAll('ı', 'i')
        .replaceAll('Ş', 'S')
        .replaceAll('ş', 's')
        .replaceAll('Ğ', 'G')
        .replaceAll('ğ', 'g')
        .replaceAll('Ü', 'U')
        .replaceAll('ü', 'u')
        .replaceAll('Ö', 'O')
        .replaceAll('ö', 'o')
        .replaceAll('Ç', 'C')
        .replaceAll('ç', 'c');
  }
}
