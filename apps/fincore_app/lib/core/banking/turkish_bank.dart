import 'package:fincore_app/core/utils/turkish_text.dart';

final class TurkishBank {
  const TurkishBank({
    required this.id,
    required this.name,
    required this.badge,
    required this.color,
  });

  final String id;
  final String name;
  final String badge;
  final int color;
}

abstract final class TurkishBanks {
  static const List<TurkishBank> values = [
    TurkishBank(id: 'akbank', name: 'Akbank', badge: 'A', color: 0xFFE30613),
    TurkishBank(
      id: 'albaraka',
      name: 'Albaraka Türk',
      badge: 'AT',
      color: 0xFF007A4D,
    ),
    TurkishBank(
      id: 'alternatifbank',
      name: 'Alternatif Bank',
      badge: 'AB',
      color: 0xFF00A6A6,
    ),
    TurkishBank(
      id: 'anadolubank',
      name: 'Anadolubank',
      badge: 'AN',
      color: 0xFF005BAA,
    ),
    TurkishBank(
      id: 'burgan',
      name: 'Burgan Bank',
      badge: 'B',
      color: 0xFF7A263A,
    ),
    TurkishBank(
      id: 'colendi',
      name: 'ColendiBank',
      badge: 'C',
      color: 0xFF6C4DFF,
    ),
    TurkishBank(
      id: 'denizbank',
      name: 'DenizBank',
      badge: 'D',
      color: 0xFF00529B,
    ),
    TurkishBank(
      id: 'emlak_katilim',
      name: 'Emlak Katılım',
      badge: 'EK',
      color: 0xFF008C95,
    ),
    TurkishBank(
      id: 'enpara',
      name: 'Enpara.com',
      badge: 'E',
      color: 0xFF6B2C91,
    ),
    TurkishBank(
      id: 'fibabanka',
      name: 'Fibabanka',
      badge: 'F',
      color: 0xFFF58220,
    ),
    TurkishBank(
      id: 'garanti',
      name: 'Garanti BBVA',
      badge: 'G',
      color: 0xFF00854A,
    ),
    TurkishBank(
      id: 'halkbank',
      name: 'Halkbank',
      badge: 'H',
      color: 0xFF0067A5,
    ),
    TurkishBank(id: 'hsbc', name: 'HSBC', badge: 'HS', color: 0xFFDB0011),
    TurkishBank(
      id: 'icbc',
      name: 'ICBC Turkey',
      badge: 'IC',
      color: 0xFFC8102E,
    ),
    TurkishBank(id: 'ing', name: 'ING', badge: 'ING', color: 0xFFFF6200),
    TurkishBank(
      id: 'isbank',
      name: 'Türkiye İş Bankası',
      badge: 'İŞ',
      color: 0xFF005DAA,
    ),
    TurkishBank(
      id: 'kuveyt_turk',
      name: 'Kuveyt Türk',
      badge: 'KT',
      color: 0xFF006A44,
    ),
    TurkishBank(
      id: 'odeabank',
      name: 'Odeabank',
      badge: 'O',
      color: 0xFF00A6B2,
    ),
    TurkishBank(id: 'qnb', name: 'QNB', badge: 'Q', color: 0xFF7B2E8E),
    TurkishBank(
      id: 'sekerbank',
      name: 'Şekerbank',
      badge: 'Ş',
      color: 0xFF00843D,
    ),
    TurkishBank(
      id: 'teb',
      name: 'Türk Ekonomi Bankası (TEB)',
      badge: 'TEB',
      color: 0xFF009A44,
    ),
    TurkishBank(
      id: 'turkiye_finans',
      name: 'Türkiye Finans',
      badge: 'TF',
      color: 0xFF7A1F5C,
    ),
    TurkishBank(
      id: 'vakif_katilim',
      name: 'Vakıf Katılım',
      badge: 'VK',
      color: 0xFFB28B34,
    ),
    TurkishBank(
      id: 'vakifbank',
      name: 'VakıfBank',
      badge: 'V',
      color: 0xFFF5B800,
    ),
    TurkishBank(
      id: 'yapi_kredi',
      name: 'Yapı Kredi',
      badge: 'YK',
      color: 0xFF17479E,
    ),
    TurkishBank(
      id: 'ziraat_katilim',
      name: 'Ziraat Katılım',
      badge: 'ZK',
      color: 0xFF9D2235,
    ),
    TurkishBank(
      id: 'ziraat',
      name: 'Ziraat Bankası',
      badge: 'Z',
      color: 0xFFE2231A,
    ),
    TurkishBank(
      id: 'other',
      name: 'Diğer Banka',
      badge: 'DB',
      color: 0xFF546E7A,
    ),
  ];

  static TurkishBank? findById(String? id) {
    if (id == null) return null;
    for (final bank in values) {
      if (bank.id == id) return bank;
    }
    return null;
  }

  static TurkishBank? findByName(String? name) {
    if (name == null) return null;
    final normalized = TurkishText.normalize(name);
    for (final bank in values) {
      if (TurkishText.normalize(bank.name) == normalized) return bank;
    }
    return findById(_legacyNameAliases[normalized]);
  }

  static const Map<String, String> _legacyNameAliases = {
    'iş bankası': 'isbank',
    'türkiye iş bankası a.ş.': 'isbank',
    'garanti': 'garanti',
    'garanti bankası': 'garanti',
    'qnb finansbank': 'qnb',
    'finansbank': 'qnb',
    'teb': 'teb',
    'türkiye ekonomi bankası': 'teb',
    'kuveyttürk': 'kuveyt_turk',
    'ziraat': 'ziraat',
    'ziraat bankası a.ş.': 'ziraat',
    'vakıflar bankası': 'vakifbank',
    'halk bankası': 'halkbank',
    'albaraka türk katılım bankası': 'albaraka',
    'türkiye finans katılım bankası': 'turkiye_finans',
  };
}
