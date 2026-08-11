import 'package:fincore_app/features/accounts/domain/value_objects/turkish_iban.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes and formats a Turkish IBAN', () {
    const raw = 'tr33-0006 1005 1978 6457 8413 26';

    expect(TurkishIban.normalize(raw), 'TR330006100519786457841326');
    expect(TurkishIban.format(raw), 'TR33 0006 1005 1978 6457 8413 26');
  });

  test('validates length, country and MOD-97 checksum', () {
    expect(TurkishIban.isValid('TR330006100519786457841326'), isTrue);
    expect(TurkishIban.isValid('TR340006100519786457841326'), isFalse);
    expect(TurkishIban.isValid('DE89370400440532013000'), isFalse);
  });
}
