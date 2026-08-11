import 'package:fincore_app/core/banking/turkish_bank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches canonical and legacy bank names', () {
    expect(TurkishBanks.findByName('Kuveyt Türk')?.id, 'kuveyt_turk');
    expect(TurkishBanks.findByName('İş Bankası')?.id, 'isbank');
    expect(TurkishBanks.findByName('QNB Finansbank')?.id, 'qnb');
  });

  test('returns null for an unknown legacy bank name', () {
    expect(TurkishBanks.findByName('Eski Özel Banka'), isNull);
  });
}
